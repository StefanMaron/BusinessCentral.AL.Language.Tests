// @expect AL0155 | A member of type QueryColumn with name 'X' is already defined in Query 'MNC Q301' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type QueryColumn with name 'X' is already defined in Query 'MNC Q301' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A query has two columns of the same name.
table 50114 "MNC T301"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50115 "MNC Q301"
{
    elements
    {
        dataitem(T; "MNC T301")
        {
            column(X; Id) { }
            column(X; Name) { }
        }
    }
}
