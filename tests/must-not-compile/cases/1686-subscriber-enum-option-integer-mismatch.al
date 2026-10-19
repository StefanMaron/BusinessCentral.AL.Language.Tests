// @expect AL0284 | The type of the parameter 'E' on the event subscriber 'EnumAsInteger' does not match the expected type 'Enum "MNC CK Enum"'.
// @expect AL0284 | The type of the parameter 'O' on the event subscriber 'OptionAsInteger' does not match the expected type 'Option'.
// @expect AL0284 | The type of the parameter 'O' on the event subscriber 'OptionAsEnum' does not match the expected type 'Option'.
// @expect AL0284 | The type of the parameter 'G' on the event subscriber 'GlobalAsText' does not match the expected type 'Integer'.
// @expect AL0284 | The type of the parameter 'RunTrigger' on the event subscriber 'RunTriggerAsInteger' does not match the expected type 'Boolean'.
// Subscriber parameter types that differ from the publisher (corpus issue 669, items 5, 10, 11, 14), same on BC 27, 28 and 29:
// an Enum received as Integer, an Option received as Integer or as an Enum, a GlobalVarAccess global received as Text, RunTrigger as Integer.
// Not errors: an Enum received as Option (warning AL0588), an Option received as an Option with other members (no diagnostic).
enum 50000 "MNC CK Enum" { value(0; A) { } value(1; B) { } }

table 50001 "MNC CK Tab"
{
    fields { field(1; Id; Integer) { } }
}

codeunit 50002 "MNC CK Pub"
{
    var
        G: Integer;

    [IntegrationEvent(false, false)]
    procedure OnE(E: Enum "MNC CK Enum")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnO(O: Option A,B,C)
    begin
    end;

    [IntegrationEvent(false, true)]
    procedure OnG(X: Integer)
    begin
    end;
}

codeunit 50003 "MNC CK Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnE', '', false, false)]
    local procedure EnumAsInteger(E: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnO', '', false, false)]
    local procedure OptionAsInteger(O: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnO', '', false, false)]
    local procedure OptionAsEnum(O: Enum "MNC CK Enum")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnG', '', false, false)]
    local procedure GlobalAsText(G: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"MNC CK Tab", 'OnAfterInsertEvent', '', false, false)]
    local procedure RunTriggerAsInteger(RunTrigger: Integer)
    begin
    end;
}
