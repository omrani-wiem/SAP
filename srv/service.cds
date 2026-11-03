using { pr } from '../db/schema';

@requires: 'authenticated-user'
service RequestService {

  @cds.redirection.target
  entity PurchaseRequests as projection on pr.PurchaseRequests {
    *,
    case status
      when 'Approved'  then 3
      when 'Rejected'  then 1
      when 'Submitted' then 2
      else 0
    end as criticality : Integer
  } actions {
    action submit() returns PurchaseRequests;

    @(requires: ['manager', 'director'])
    action approve() returns PurchaseRequests;

    @(requires: ['manager', 'director'])
    action reject(reason : String) returns PurchaseRequests;
  };

  entity Items as projection on pr.Items;

  // --- Dashboard (inchangé) ---
  @readonly
  entity StatusStats as select from pr.PurchaseRequests {
    key status,
    count(*)         as nbRequests  : Integer,
    sum(totalAmount) as totalAmount : Decimal(15,2)
  } group by status;

  @readonly
  entity DepartmentStats as select from pr.PurchaseRequests {
    key department,
    count(*)                as nbRequests    : Integer,
    sum(totalAmount)        as totalAmount   : Decimal(15,2),
    avg(approvalDelayHours) as avgDelayHours : Decimal(10,1)
  } group by department;
}