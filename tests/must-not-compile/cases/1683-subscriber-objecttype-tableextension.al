// @expect AL0132 | 'ObjectType' does not contain a definition for 'TableExtension'
// A subscriber that names the tableextension as the publisher object (corpus issue 669, item 2). An event declared in a tableextension
// is subscribed through ObjectType::Table and the base table (tests/al-language/extensionevents/TestExtensionDeclaredEvents.al).
table 50000 "MNC CK Tab"
{
    fields { field(1; Id; Integer) { } }
}

tableextension 50001 "MNC CK TabExt" extends "MNC CK Tab"
{
    [IntegrationEvent(false, false)]
    local procedure OnExtEv()
    begin
    end;
}

codeunit 50002 "MNC CK Sub"
{
    [EventSubscriber(ObjectType::TableExtension, 50001, 'OnExtEv', '', false, false)]
    local procedure OnExtEv()
    begin
    end;
}
