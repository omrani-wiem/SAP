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

  UI.Identification: [
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.submit',  Label: 'Soumettre' },
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.approve', Label: 'Approuver' },
    { $Type: 'UI.DataFieldForAction', Action: 'RequestService.reject',  Label: 'Rejeter' }
  ],

  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Informations générales', Target: '@UI.FieldGroup#General' },
    { $Type: 'UI.ReferenceFacet', Label: 'Articles',               Target: 'items/@UI.LineItem' }
  ],

  UI.FieldGroup #General: {
    Data: [
      { Value: title },
      { Value: requester },
      { Value: department },
      { Value: totalAmount },
      { Value: status, Criticality: criticality },
      { Value: submittedAt,        Label: 'Soumise le' },
      { Value: decidedAt,          Label: 'Décidée le' },
      { Value: approvalDelayHours, Label: 'Délai (heures)' }
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

// ---------- Dashboard : demandes par statut ----------
annotate service.StatusStats with @(
  UI.Chart: {
    $Type               : 'UI.ChartDefinitionType',
    Title               : 'Demandes par statut',
    ChartType           : #Column,
    Dimensions          : [ status ],
    DynamicMeasures     : [ '@Analytics.AggregatedProperty#nb' ]
  },
  UI.LineItem: [
    { Value: status,      Label: 'Statut' },
    { Value: nbRequests,  Label: 'Nombre' },
    { Value: totalAmount, Label: 'Montant total' }
  ],
  UI.PresentationVariant: {
    Visualizations: [ '@UI.Chart', '@UI.LineItem' ]
  }
);

annotate service.StatusStats with @(
  Analytics.AggregatedProperty #nb: {
    $Type                : 'Analytics.AggregatedPropertyType',
    Name                 : 'nb',
    AggregatableProperty : nbRequests,
    AggregationMethod    : 'sum',
    ![@Common.Label]     : 'Nombre de demandes'
  }
);

// ---------- Dashboard : par département ----------
annotate service.DepartmentStats with @(
  UI.LineItem: [
    { Value: department,    Label: 'Département' },
    { Value: nbRequests,    Label: 'Nombre' },
    { Value: totalAmount,   Label: 'Montant total' },
    { Value: avgDelayHours, Label: 'Délai moyen (h)' }
  ]
);