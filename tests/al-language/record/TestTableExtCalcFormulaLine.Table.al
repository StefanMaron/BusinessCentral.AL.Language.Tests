/// <summary>
/// The TARGET table the FlowFields on "TXC Parent" aggregate. It declares only the columns a
/// formula needs to link and narrow on; the field the suite is actually about -- "TXC Ext
/// Weight" -- is added by "TXC ILE Ext", a SEPARATE tableextension, so a CalcFormula declared
/// on another table has to resolve it by name across extension boundaries.
///
/// Seeded values are chosen so every where-arm lands on a different total: see "TXC Tests".
/// </summary>
table 60819 "TXC Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Source No."; Code[20]) { }
        field(3; "Item No."; Code[20]) { }
        field(4; "Posting Date"; Date) { }
        field(5; "Sales Amount"; Decimal) { }
        field(6; Quantity; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
