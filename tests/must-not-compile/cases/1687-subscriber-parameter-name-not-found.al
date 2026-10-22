// @expect AL0282 | The member referenced by event subscriber 'ValidateWithRunTrigger' parameter 'RunTrigger' is not found.
// @expect AL0282 | The member referenced by event subscriber 'WrongRecName' parameter 'Record' is not found.
// @expect AL0282 | The member referenced by event subscriber 'NoSuchGlobal' parameter 'Zzz' is not found.
// Subscriber parameters that match no publisher parameter (corpus issue 669, items 5, 13, 14), same on BC 27, 28 and 29:
// RunTrigger on an OnAfterValidateEvent subscriber, a table event parameter named Record instead of Rec, and on a
// GlobalVarAccess event a name that is neither a parameter nor a global. Names that differ only by case (REC, runtrigger) compile.
table 50000 "MNC CK Tab"
{
    fields { field(1; Id; Integer) { } field(2; Val; Integer) { } }
}

codeunit 50001 "MNC CK Pub"
{
    var
        G: Integer;

    [IntegrationEvent(false, true)]
    procedure OnG(X: Integer)
    begin
    end;
}

codeunit 50002 "MNC CK Sub"
{
    [EventSubscriber(ObjectType::Table, Database::"MNC CK Tab", 'OnAfterValidateEvent', 'Val', false, false)]
    local procedure ValidateWithRunTrigger(var Rec: Record "MNC CK Tab"; RunTrigger: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"MNC CK Tab", 'OnAfterInsertEvent', '', false, false)]
    local procedure WrongRecName(var Record: Record "MNC CK Tab")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnG', '', false, false)]
    local procedure NoSuchGlobal(Zzz: Integer)
    begin
    end;
}
