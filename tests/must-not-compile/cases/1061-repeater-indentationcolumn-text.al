// @expect AL0316 | The expression must be of Integer type. Convert the expression or use an Integer variable.
// A tree repeater whose IndentationColumn is a Text field.
table 51061 "MNC AH T1061"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Lvl; Decimal) { }
        field(3; Opt; Option) { OptionMembers = A,B; }
        field(4; Par; Code[20]) { }
        field(5; Txt; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51061 "MNC AH P1061"
{
    PageType = List;
    SourceTable = "MNC AH T1061";
    layout
    {
        area(Content)
        {
            repeater(R) { ShowAsTree = true; IndentationColumn = Rec.Txt; field(Id2; Rec.Id) { } }
        }
    }
}
