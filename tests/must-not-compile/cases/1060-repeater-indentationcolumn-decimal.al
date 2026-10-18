// @expect AL0316 | The expression must be of Integer type
// A tree repeater whose IndentationColumn is a Decimal field.
table 51060 "MNC AH T1060"
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
page 51060 "MNC AH P1060"
{
    PageType = List;
    SourceTable = "MNC AH T1060";
    layout
    {
        area(Content)
        {
            repeater(R) { ShowAsTree = true; IndentationColumn = Rec.Lvl; field(Id2; Rec.Id) { } }
        }
    }
}
