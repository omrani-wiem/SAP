using RequestService as service from '../srv/service';

annotate service.PurchaseRequests with @(
  UI.HeaderInfo: {
    TypeName       : 'Demande d''achat',
    TypeNamePlural : 'Demandes d''achat',
    Title          : { Value: title },
    Description    : { Value: requester }
  },

  UI.SelectionFields: [ department, status ],

  UI.LineItem: [
    { Value: title,       Label: 'Titre' },
    { Value: requester,   Label: 'Demandeur' },
    { Value: department,  Label: 'Département' },
    { Value: totalAmount, Label: 'Montant' },
    { Value: status,      Label: 'Statut', Criticality: criticality }
  ],

  UI.Facets: [
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Informations générales',
      Target : '@UI.FieldGroup#General'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Label  : 'Articles',
      Target : 'items/@UI.LineItem'
    }
  ],

  UI.FieldGroup #General: {
    Data: [
      { Value: title },
      { Value: requester },
      { Value: department },
      { Value: totalAmount },
      { Value: status, Criticality: criticality }
    ]
  }
);

annotate service.Items with @(
  UI.LineItem: [
    { Value: material,  Label: 'Article' },
    { Value: quantity,  Label: 'Quantité' },
    { Value: unitPrice, Label: 'Prix unitaire' }
  ]
);