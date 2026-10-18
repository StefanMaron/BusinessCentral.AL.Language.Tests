// @expect AL0208 | The expression must be of Boolean type. Use a comparison or boolean expression.
// QuickEntry takes a boolean constant.
table 59868 "MNC Z Row 0868"
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
page 52868 "MNC Z Card 0868"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0868";
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
pageextension 54868 "MNC Z Ext 0868" extends "MNC Z Card 0868"
{
    layout { modify(Name) { QuickEntry = 'yes'; } }
}
