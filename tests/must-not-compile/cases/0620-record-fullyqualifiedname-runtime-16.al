// @expect AL0666 | 'FullyQualifiedName' is not available in runtime version '16.
// @until 27
// Record.FullyQualifiedName needs runtime 17.0; the corpus app runs on runtime 16.1 on BC 27 (the AL 16 compiler said AL0132, the member does not exist; AL 30, the compiler of the corpus CI now, says AL0666). Issue 591 item 2: not observable at runtime 16, so only the refusal is pinned.
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
