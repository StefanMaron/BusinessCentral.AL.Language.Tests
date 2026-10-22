// @expect AL0347 | The methods 'Average, Sum, Max, Min' can only be used on Columns that have a Decimal, BigInteger, Integer, or Duration type
// A query column with Method = Max over a Date field (corpus #667: Sum/Min/Max on non-numeric columns; 0109 has Average over Date).
table 50112 "MNC CG Max Date Row"
{
    fields { field(1; Id; Integer) { } field(2; D; Date) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50113 "MNC CG Max Over Date"
{
    elements
    {
        dataitem(Row; "MNC CG Max Date Row")
        {
            column(MaxD; D) { Method = Max; }
        }
    }
}
