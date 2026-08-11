/// <summary>
/// The source table the FlowFields in "CFV Header" aggregate. "Ref Amount" is a plain stored
/// column that the seeded rows set to a value which may or may not equal the parent's
/// <c>"Total Amount"</c> FlowField, so a where-condition that compares against that FlowField
/// selects a strict subset of the rows the parent link alone selects.
/// </summary>
table 60940 "CFV Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc No."; Code[20]) { }
        field(3; Amount; Decimal) { }

        /// A NORMAL decimal whose value is compared against the parent's "Total Amount"
        /// FlowField by the where-conditions on "Matched Amount" / "Matched Count".
        field(4; "Ref Amount"; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
