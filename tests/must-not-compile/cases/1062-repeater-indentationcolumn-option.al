// @expect AL0316 | The expression must be of Integer type. Convert the expression or use an Integer variable.
// A tree repeater whose IndentationColumn is an Option field.
table 51062 "MNC AH T1062"
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
page 51062 "MNC AH P1062"
{
    PageType = List;
    SourceTable = "MNC AH T1062";
    layout
    {
        area(Content)
        {
            repeater(R) { ShowAsTree = true; IndentationColumn = Rec.Opt; field(Id2; Rec.Id) { } }
        }
    }
}
