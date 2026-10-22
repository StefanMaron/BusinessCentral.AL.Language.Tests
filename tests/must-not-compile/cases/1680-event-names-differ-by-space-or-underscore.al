// @expect AL0757 | The metadata name of Method 'Foo_Bar' conflicts with Method 'Foo Bar' defined in Codeunit 'MNC CK Pub'
// @expect AL0757 | The metadata name of Method 'Foo Bar' conflicts with Method 'Foo_Bar' defined in Codeunit 'MNC CK Pub'
// @expect AL0757 | The metadata name of Method 'Foo_Bar' conflicts with Method 'Foo Bar' defined in Codeunit 'MNC CK Sub'
// @expect AL0757 | The metadata name of Method 'Foo Bar' conflicts with Method 'Foo_Bar' defined in Codeunit 'MNC CK Sub'
// Two event publishers in one codeunit named "Foo Bar" and Foo_Bar, and two event subscribers in one codeunit with the same two names.
// BC 27, 28 and 29 (runtime 16.1, 17.1, 18.0) all give error AL0757 on both declarations of each pair (corpus issue 669, item 1).
codeunit 50000 "MNC CK Pub"
{
    [IntegrationEvent(false, false)]
    local procedure "Foo Bar"()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure Foo_Bar()
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnX()
    begin
    end;
}

codeunit 50001 "MNC CK Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnX', '', false, false)]
    local procedure "Foo Bar"()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnX', '', false, false)]
    local procedure Foo_Bar()
    begin
    end;
}
