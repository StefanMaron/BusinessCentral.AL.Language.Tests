// @expect AL0844 | The property 'DateFormula' can only be used if the field's type is one of these values: 'Char,Code,Label,String,Text,TextConst'.
// Page field DateFormula on a Decimal field.
table 50882 "MNC AA T882"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T882"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50882 "MNC AA P882"
{
    PageType = Card;
    SourceTable = "MNC AA T882";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Amt) { DateFormula = true; }
        }
    }
}
