// @expect AL0132 | 'Record "MNC IsDirty Row 0960"' does not contain a definition for 'IsDirty'
// @until 28
// Record.IsDirty() exists from BC 29 (AL 18); BC 27 and 28 reject it. On BC 29 the call needs runtime 18.0, which the corpus app does not use (case 0998).
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
