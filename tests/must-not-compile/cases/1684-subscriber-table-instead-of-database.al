// @expect AL0118 | The name 'Table' does not exist in the current context.
// A table event subscriber that names the table with Table::Customer instead of Database::Customer (corpus issue 669, item 4).
codeunit 50000 "MNC CK Sub"
{
    [EventSubscriber(ObjectType::Table, Table::Customer, 'OnAfterInsertEvent', '', false, false)]
    local procedure S(var Rec: Record Customer)
    begin
    end;
}
