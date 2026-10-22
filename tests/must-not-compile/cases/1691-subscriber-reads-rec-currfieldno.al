// @expect AL0132 | 'Record Customer' does not contain a definition for 'CurrFieldNo'
// @expect AL0161 | 'CurrFieldNo' is inaccessible due to its protection level
// A table event subscriber in a codeunit reads Rec.CurrFieldNo: for a table of another app CurrFieldNo is not a member (AL0132), for a table of
// the same app it is not accessible (AL0161). CurrFieldNo can be read only inside the table and its table extensions; a validate event
// subscriber gets it as its CurrFieldNo parameter (corpus issue 669, item 30).
table 51691 "MNC CL CFN 1691"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
}

codeunit 51691 "MNC CL CFN Sub 1691"
{
    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure AfterValidateCustomerName(var Rec: Record Customer; var xRec: Record Customer; CurrFieldNo: Integer)
    begin
        if Rec.CurrFieldNo = 0 then
            exit;
    end;

    [EventSubscriber(ObjectType::Table, Database::"MNC CL CFN 1691", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure AfterValidateOwnName(var Rec: Record "MNC CL CFN 1691"; var xRec: Record "MNC CL CFN 1691"; CurrFieldNo: Integer)
    begin
        if Rec.CurrFieldNo = 0 then
            exit;
    end;
}
