// @expect AL0347 | The methods 'Average, Sum, Max, Min' can only be used on Columns that have a Decimal, BigInteger, Integer, or Duration type
// A query column with Method = Sum over a Text field.
table 50112 "MNC Sum Text Row"
{
    fields { field(1; Id; Integer) { } field(2; Txt; Text[20]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50113 "MNC Sum Over Text"
{
    elements
    {
        dataitem(Row; "MNC Sum Text Row")
        {
            column(SumTxt; Txt) { Method = Sum; }
        }
    }
}
