// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Option'
// Unary minus on an Option field of a record, assigned back to the field (corpus issue 672, item 42; the form of
// microsoft/AL issue 3109: PrintJobLine.Alignment := -Alignment).
table 51532 "MNC BU T1532"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Alignment; Option) { OptionMembers = Left,Center,Right; }
    }
}

codeunit 51533 "MNC BU 1532"
{
    procedure Run1()
    var
        Rec: Record "MNC BU T1532";
    begin
        Rec.Alignment := -Rec.Alignment;
    end;
}
