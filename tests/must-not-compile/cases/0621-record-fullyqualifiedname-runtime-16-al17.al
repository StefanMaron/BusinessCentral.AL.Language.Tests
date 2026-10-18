// @expect AL0666 | 'FullyQualifiedName' is not available in runtime version '16.
// @until 27
// Since the runtime move the corpus apps run on runtime 17.1 on BC 28 and 18.0 on BC 29, where Record.FullyQualifiedName compiles; this case now repeats 0620 for BC 27.
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
