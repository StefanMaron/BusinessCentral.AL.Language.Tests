// @expect AL0347 | The methods 'Average, Sum, Max, Min' can only be used on Columns that have a Decimal, BigInteger, Integer, or Duration type
// A query column with Method = Average over a Date field.
table 50114 "MNC Avg Date Row"
{
    fields { field(1; Id; Integer) { } field(2; Dt; Date) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50115 "MNC Average Over Date"
{
    elements
    {
        dataitem(Row; "MNC Avg Date Row")
        {
            column(AvgDt; Dt) { Method = Average; }
        }
    }
}
