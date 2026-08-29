// A query column with Method = Sum/Count/Average/Min/Max implicitly groups by every
// OTHER (non-aggregated) column in the query — the same GROUP BY the compiled SQL SELECT
// performs. Reuses the "QJ Order" table already established by the sibling join suite
// (TestQueryJoin.al) rather than introducing a new fixture table for the same shape.
query 60760 "QJ Order Sum"
{
    QueryType = Normal;
    OrderBy = ascending(CustNo);

    elements
    {
        dataitem(Order; "QJ Order")
        {
            column(CustNo; "Customer No.") { }
            column(TotalAmount; Amount) { Method = Sum; }
            column(CountAmount; Amount) { Method = Count; }
            column(AverageAmount; Amount) { Method = Average; }
            column(MinAmount; Amount) { Method = Min; }
            column(MaxAmount; Amount) { Method = Max; }
        }
    }
}
