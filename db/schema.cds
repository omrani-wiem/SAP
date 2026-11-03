namespace pr;

using { cuid, managed } from '@sap/cds/common';

entity PurchaseRequests : cuid, managed {
  title        : String(100);
  requester    : String(60);
  department   : String(40);
  status       : String(20) default 'Draft';
  totalAmount  : Decimal(12,2);
  submittedAt  : Timestamp;
  decidedAt    : Timestamp;
  approvalDelayHours : Decimal(10,1);
  items        : Composition of many Items on items.request = $self;
}

entity Items : cuid {
  request   : Association to PurchaseRequests;
  material  : String(60);
  quantity  : Integer;
  unitPrice : Decimal(10,2);
}