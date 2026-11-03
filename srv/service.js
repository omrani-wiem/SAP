const cds = require('@sap/cds');

const SEUIL_DIRECTEUR = 1000;

module.exports = cds.service.impl(function () {
  const { PurchaseRequests, Items } = this.entities;

  
  async function recalcTotal(requestId, tx) {
    const items = await tx.run(SELECT.from(Items).where({ request_ID: requestId }));
    const total = items.reduce((s, i) => s + i.quantity * i.unitPrice, 0);
    await tx.run(
      UPDATE(PurchaseRequests).set({ totalAmount: total }).where({ ID: requestId })
    );
  }

  this.after(['CREATE', 'UPDATE', 'DELETE'], Items, async (data, req) => {
    const id = data?.request_ID;
    if (id) await recalcTotal(id, cds.tx(req));
  });

  async function getRequest(req) {
    const { ID } = req.params[0];
    const r = await SELECT.one.from(PurchaseRequests).where({ ID });
    if (!r) req.reject(404, 'Demande introuvable');
    return r;
  }


  function delayHours(submittedAt) {
    if (!submittedAt) return null;
    const ms = Date.now() - new Date(submittedAt).getTime();
    return Math.round((ms / 3600000) * 10) / 10;
  }


  this.on('submit', async (req) => {
    const r = await getRequest(req);
    if (r.status !== 'Draft')
      return req.error(400, `Seul un brouillon peut être soumis (statut actuel : ${r.status})`);
    if (!r.totalAmount || r.totalAmount <= 0)
      return req.error(400, 'Le montant doit être supérieur à 0');

    await UPDATE(PurchaseRequests)
      .set({ status: 'Submitted', submittedAt: new Date().toISOString() })
      .where({ ID: r.ID });
    return SELECT.one.from(PurchaseRequests).where({ ID: r.ID });
  });

  
  this.on('approve', async (req) => {
    const r = await getRequest(req);
    if (r.status !== 'Submitted')
      return req.error(400, `Seule une demande soumise peut être approuvée (statut actuel : ${r.status})`);

    const roleRequis = r.totalAmount >= SEUIL_DIRECTEUR ? 'director' : 'manager';
    if (!req.user.is(roleRequis) && !req.user.is('director'))
      return req.error(403, `Approbation réservée au rôle : ${roleRequis}`);

    await UPDATE(PurchaseRequests).set({
      status: 'Approved',
      decidedAt: new Date().toISOString(),
      approvalDelayHours: delayHours(r.submittedAt)
    }).where({ ID: r.ID });
    return SELECT.one.from(PurchaseRequests).where({ ID: r.ID });
  });

  
  this.on('reject', async (req) => {
    const r = await getRequest(req);
    if (r.status !== 'Submitted')
      return req.error(400, `Seule une demande soumise peut être rejetée (statut actuel : ${r.status})`);
    if (!req.data.reason)
      return req.error(400, 'Un motif de rejet est obligatoire');

    await UPDATE(PurchaseRequests).set({
      status: 'Rejected',
      decidedAt: new Date().toISOString(),
      approvalDelayHours: delayHours(r.submittedAt)
    }).where({ ID: r.ID });
    return SELECT.one.from(PurchaseRequests).where({ ID: r.ID });
  });
});