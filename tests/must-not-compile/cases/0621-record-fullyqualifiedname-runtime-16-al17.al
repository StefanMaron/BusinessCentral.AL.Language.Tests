// @expect AL0666 | 'FullyQualifiedName' is not available in runtime version '16.0'. The supported runtime versions are: '17.0' or greater.
// @from 28
// Record.FullyQualifiedName needs runtime 17.0; the app runs on runtime 16.0 (AL 17 and later report that the runtime is too low). Issue 591 item 2: not observable at runtime 16, so only the refusal is pinned.
table 50000 "MNC Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC FQN"
{
    procedure Probe(): Text
    var
        Row: Record "MNC Row";
    begin
        exit(Row.FullyQualifiedName());
    end;
}
