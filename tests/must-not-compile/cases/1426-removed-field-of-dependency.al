// @expect AL0433 | Field 'Coupled to CRM' is removed. Reason: Replaced by flow field Coupled to Dataverse. Tag: 26.0.
// A dependent app names a field that its dependency (Base Application, Customer."Coupled to CRM") marks ObsoleteState = Removed: error
// AL0433, no package. A Pending field of a dependency gives warning AL0432 and the package is built (the corpus app builds with such
// warnings). Corpus issue 664 item 109 (microsoft/AL#2092). Writer BO.
codeunit 51433 "MNC BO 1426"
{
    procedure Q()
    var
        C: Record Customer;
    begin
        C.SetRange("Coupled to CRM", true);
    end;
}
