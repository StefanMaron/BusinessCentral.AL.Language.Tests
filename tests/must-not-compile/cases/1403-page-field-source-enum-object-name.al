// @expect AL0156 | '"MNC BN E1403"' is not a valid field type. Use basic types (Text, Integer, Decimal, etc.) or reference custom types (Record, Enum, etc.).
// A page field whose source expression is the name of an enum object (microsoft/AL issues 5409, 5415: once a publish failure "Unexpected
// value 'EnumType' of type BoundKind").
enum 51403 "MNC BN E1403"
{
    value(0; A0) { }
}

table 51403 "MNC BN T1403"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 51403 "MNC BN P1403"
{
    PageType = Card;
    SourceTable = "MNC BN T1403";

    layout
    {
        area(Content)
        {
            field(X; "MNC BN E1403") { ApplicationArea = All; }
        }
    }
}
