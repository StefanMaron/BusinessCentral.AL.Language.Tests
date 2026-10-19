// @expect AL0844 | The property 'BlankZero' can only be used if the field's type is one of these values: 'BigInteger,Boolean,Integer,Decimal,Duration,Enum,Option'.
// @expect AL0844 | The property 'BlankZero' can only be used if the field's type is one of these values: 'BigInteger,Boolean,Integer,Decimal,Duration,Enum,Option'.
// BlankZero on a Guid table field and on a page control bound to it (microsoft/AL issue 451): both are refused. BlankZero on a Text
// control of a page extension: case 0869.
table 51435 "MNC BP T1435"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; G; Guid) { BlankZero = true; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51435 "MNC BP P1435"
{
    PageType = Card;
    SourceTable = "MNC BP T1435";

    layout
    {
        area(Content)
        {
            field(G; Rec.G) { BlankZero = true; }
        }
    }
}
