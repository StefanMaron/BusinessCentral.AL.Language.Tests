// Fixture for query/TestQueryFlowFieldColumn.al — a query column backed by a FlowField.
table 60974 "QFF Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
