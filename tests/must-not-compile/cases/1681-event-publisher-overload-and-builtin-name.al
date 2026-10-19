// @expect AL0155 | A member of type Method with name 'OnX' is already defined in Codeunit 'MNC CK Pub'
// @expect AL0155 | A member of type Method with name 'OnX' is already defined in Codeunit 'MNC CK Pub'
// @expect AL0155 | A member of type Method with name 'Run' is already defined in Codeunit 'MNC CK Run'
// Two event publishers with one name and different parameter types (an event cannot be overloaded, unlike a plain procedure, case 0043),
// and an event publisher named Run in a codeunit (Run is a built-in member of Codeunit). The lead (corpus issue 669, item 1) named
// AL0818 and AL0755 for these; BC 27, 28 and 29 give AL0155. A table event named Insert only warns (AL0524), a local one named Modify compiles.
codeunit 50000 "MNC CK Pub"
{
    [IntegrationEvent(false, false)]
    local procedure OnX(A: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnX(A: Text)
    begin
    end;
}

codeunit 50001 "MNC CK Run"
{
    [IntegrationEvent(false, false)]
    local procedure Run()
    begin
    end;
}
