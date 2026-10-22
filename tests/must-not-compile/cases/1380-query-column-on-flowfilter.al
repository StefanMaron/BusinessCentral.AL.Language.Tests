// @expect AL0353 | A Column must have a valid data source or have the 'Method' property set to 'Count'
// @expect AL0815 | The source of a column cannot be a flow filter.
// Code[50] and Text take it. A query column whose source is a FlowFilter field gives AL0353 and AL0815 (the tracker named AL0814).
// Corpus #664 item 5. A query column whose source is a FlowFilter field gives AL0353 and AL0815 (the lead named AL0814).
table 51380 "MNC BM T1380"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; FFi; Code[20]) { FieldClass = FlowFilter; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
query 51380 "MNC BM Q1380"
{
    elements
    {
        dataitem(D; "MNC BM T1380")
        {
            column(Id; Id) { }
            column(FFi; FFi) { }
        }
    }
}
