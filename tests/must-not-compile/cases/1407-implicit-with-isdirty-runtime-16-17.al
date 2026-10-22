// @until 28
// @expect AL0666 | 'IsDirty' is not available in runtime version '
// In a codeunit with TableNo, OnRun has an implicit `with Rec`. A bare IsDirty() binds to the record method Record.IsDirty (runtime 18.0)
// before the codeunit's own local procedure IsDirty, so on runtime 16.1 and 17.1 (BC 27, 28) the call is refused instead of calling the
// local procedure. On BC 29 it compiles and calls the record method (tests/al-language/events/lt-with-statement-scopes/WithStatementAmbiguous.al).
// The method's own runtime check on an explicit call is case 0998.
table 51407 "MNC BN T1407"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 51407 "MNC BN C1407"
{
    TableNo = "MNC BN T1407";

    trigger OnRun()
    begin
        if IsDirty() then;
    end;

    local procedure IsDirty(): Boolean
    begin
        exit(false);
    end;
}
