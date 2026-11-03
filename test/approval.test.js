const cds = require('@sap/cds');

// Démarre le serveur CAP en mémoire, avec les données CSV
const { GET, POST } = cds.test(__dirname + '/..');

const BASE = '/odata/v4/request/PurchaseRequests';
const as = (user) => ({ auth: { username: user, password: user } });

// IDs issus de db/data/pr-PurchaseRequests.csv
const ORDINATEURS = '11111111-1111-1111-1111-111111111111'; // Submitted, 4500
const LICENCE     = '33333333-3333-3333-3333-333333333333'; // Draft, 1200
const CAFE        = '55555555-5555-5555-5555-555555555555'; // Submitted, 150

const action = (id, name, data = {}, user = 'omran') =>
  POST(`${BASE}(${id})/RequestService.${name}`, data, as(user));

// Les tests s'exécutent dans l'ordre et partagent la même base en mémoire
describe('Workflow d\'approbation', () => {


  describe('Règles de rôle', () => {

    test('un utilisateur sans rôle ne peut pas rejeter', async () => {
      await expect(action(ORDINATEURS, 'reject', { reason: 'test' }, 'omran'))
        .rejects.toMatchObject({ response: { status: 403 } });
    });

    test('un utilisateur sans rôle ne peut pas approuver une petite demande', async () => {
      await expect(action(CAFE, 'approve', {}, 'omran'))
        .rejects.toMatchObject({ response: { status: 403 } });
    });

    test('un manager peut approuver une demande < 1000', async () => {
      const res = await action(CAFE, 'approve', {}, 'alice');
      expect(res.status).toBe(200);
      expect(res.data.status).toBe('Approved');
    });

    test('un manager ne peut pas approuver une demande >= 1000', async () => {
      await expect(action(ORDINATEURS, 'approve', {}, 'alice'))
        .rejects.toMatchObject({ response: { status: 403 } });
    });

    test('un directeur peut approuver une demande >= 1000', async () => {
      const res = await action(ORDINATEURS, 'approve', {}, 'bob');
      expect(res.status).toBe(200);
      expect(res.data.status).toBe('Approved');
    });

    test('le délai d\'approbation est calculé', async () => {
      const res = await GET(`${BASE}(${ORDINATEURS})`, as('bob'));
      expect(res.data.decidedAt).toBeTruthy();
      expect(res.data.approvalDelayHours).not.toBeNull();
    });

    
  });

  describe('Machine à états', () => {
    test('un brouillon peut être soumis', async () => {
      const res = await action(LICENCE, 'submit');
      expect(res.status).toBe(200);
      expect(res.data.status).toBe('Submitted');
      expect(res.data.submittedAt).toBeTruthy();
    });

    test('une double soumission est refusée', async () => {
      await expect(action(LICENCE, 'submit'))
        .rejects.toMatchObject({ response: { status: 400 } });
    });

    test('un rejet sans motif est refusé', async () => {
      await expect(action(LICENCE, 'reject', {}, 'bob'))
        .rejects.toMatchObject({ response: { status: 400 } });
    });

    test('un rejet avec motif réussit', async () => {
      const res = await action(LICENCE, 'reject', { reason: 'Budget insuffisant' }, 'bob');
      expect(res.status).toBe(200);
      expect(res.data.status).toBe('Rejected');
    });

    test('une demande rejetée ne peut plus être approuvée', async () => {
      await expect(action(LICENCE, 'approve', {}, 'bob'))
        .rejects.toMatchObject({ response: { status: 400 } });
    });
  });
});