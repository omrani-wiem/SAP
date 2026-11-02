using { pr } from '../db/schema';

service RequestService {
  entity PurchaseRequests as projection on pr.PurchaseRequests {
    *,
    case status
      when 'Approved'  then 3
      when 'Rejected'  then 1
      when 'Submitted' then 2
      else 0
    end as criticality : Integer
  } actions {
    action submit();
    action approve();
    action reject(reason : String);
  };

  entity Items as projection on pr.Items;
}