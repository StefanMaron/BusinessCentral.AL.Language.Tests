// Fixture for query/TestQueryFlowFieldColumn.al — a query column backed by a FlowField.
table 60975 "QFF Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("QFF Line".Amount where("Header No." = field("No.")));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
