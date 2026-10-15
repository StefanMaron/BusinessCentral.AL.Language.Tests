// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A label is assigned to.
codeunit 50168 "MNC C350"
{
    procedure Run1()
    var
        Lbl: Label 'abc';
    begin
        Lbl := 'x';
    end;
}
