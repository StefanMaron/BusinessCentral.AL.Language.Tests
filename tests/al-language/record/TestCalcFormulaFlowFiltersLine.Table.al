/// <summary>
/// The source table the FlowFields in "CFF Header" aggregate. The seeded rows differ in
/// "Posting Date", "Account No." and "Doc No." so that each flow-filter shape selects a
/// DIFFERENT subset — a where-condition that is dropped shows up as a different total.
/// </summary>
table 60930 "CFF Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc No."; Code[20]) { }
        field(3; "Posting Date"; Date) { }
        field(4; Amount; Decimal) { }
        field(5; "Account No."; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
