// @expect AL0132 | 'Record "MNC Row"' does not contain a definition for 'FullyQualifiedName'
// @until 27
// Record.FullyQualifiedName needs runtime 17.0; the app runs on runtime 16.0 (the AL 16 compiler does not know the member at all). Issue 591 item 2: not observable at runtime 16, so only the refusal is pinned.
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
