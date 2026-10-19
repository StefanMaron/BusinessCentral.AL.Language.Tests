// @expect AL0347 | The methods 'Average, Sum, Max, Min' can only be used on Columns that have a Decimal, BigInteger, Integer, or Duration type
// A query column with Method = Min over a Code field (corpus #667: Sum/Min/Max on non-numeric columns; 0108 has Sum over Text).
table 50112 "MNC CG Min Code Row"
{
    fields { field(1; Id; Integer) { } field(2; No; Code[20]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50113 "MNC CG Min Over Code"
{
    elements
    {
        dataitem(Row; "MNC CG Min Code Row")
        {
            column(MinNo; No) { Method = Min; }
        }
    }
}
