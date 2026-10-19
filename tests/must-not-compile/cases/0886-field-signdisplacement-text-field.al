// @expect AL0844 | The property 'SignDisplacement' can only be used if the field's type is one of these values: 'BigInteger,Boolean,Date,Decimal,Duration,Integer,Time,DateTime'.
// Page field SignDisplacement on a Text field.
table 50889 "MNC AA T889"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T889"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50889 "MNC AA P889"
{
    PageType = Card;
    SourceTable = "MNC AA T889";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(T; Rec.Txt) { SignDisplacement = 1; }
        }
    }
}
