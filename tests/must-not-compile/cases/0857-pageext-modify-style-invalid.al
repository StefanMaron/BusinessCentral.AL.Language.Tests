// @expect AL0169 | The option value 'Red' is not valid
// Style knows the ten named styles only.
table 59857 "MNC Z Row 0857"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 52857 "MNC Z Card 0857"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0857";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54857 "MNC Z Ext 0857" extends "MNC Z Card 0857"
{
    layout { modify(Name) { Style = Red; StyleExpr = true; } }
}
