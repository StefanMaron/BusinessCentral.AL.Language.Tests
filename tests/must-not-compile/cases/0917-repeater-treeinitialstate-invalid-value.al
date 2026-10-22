// @expect AL0169 | The option value 'HalfOpen' is not valid
// Page repeater TreeInitialState with an unknown value.
table 50924 "MNC AA T924"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T924"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50924 "MNC AA P924"
{
    PageType = List;
    SourceTable = "MNC AA T924";
    layout
    {
        area(Content)
        {
            repeater(R) { ShowAsTree = true; IndentationColumn = Rec.Lvl; TreeInitialState = HalfOpen; field(Id2; Rec.Id) { } }
        }
    }
}
