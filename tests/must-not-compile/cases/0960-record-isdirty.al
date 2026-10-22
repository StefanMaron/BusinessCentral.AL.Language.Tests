// @expect AL0132 | 'Record "MNC IsDirty Row 0960"' does not contain a definition for 'IsDirty'
// @until 28
// @max-al 17
// Record.IsDirty() exists from BC 29 (AL 18); BC 27 and 28 reject it. Runtime tests for BC 29: tests/al-language/lt-ac.
table 58960 "MNC IsDirty Row 0960"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

codeunit 58961 "MNC IsDirty 0960"
{
    procedure Run1(): Boolean
    var
        Row: Record "MNC IsDirty Row 0960";
    begin
        exit(Row.IsDirty());
    end;
}
