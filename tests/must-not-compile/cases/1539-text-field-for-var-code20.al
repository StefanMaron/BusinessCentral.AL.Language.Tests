// @expect AL0133 | Argument 1: cannot convert from 'Text[100]' to 'var Code[20]'
// A Text[100] table field passed to a var Code[20] parameter (corpus issue 672, item 56; the value parameter form compiles,
// see tests/al-language/text/lt-text-functions/TextAssign.Codeunit.al, LT_BU_TextAssign_LongTextToCode20Parameter).
table 51539 "MNC BU T1539"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[100]) { }
    }
}

codeunit 51540 "MNC BU 1539"
{
    procedure Run1()
    var
        Rec: Record "MNC BU T1539";
    begin
        TakeCode(Rec.Name);
    end;

    procedure TakeCode(var TemplateName: Code[20])
    begin
    end;
}
