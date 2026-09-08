// Fixture for TestFieldDataClassificationInheritance.al.
//
// The table declares DataClassification = SystemMetadata, and the four fields differ ONLY in
// how they relate to that declaration: one is silent, one declares its own value, one is a
// Blob that is silent, one is a FlowField that is silent. So the table-level value is the
// answer for exactly one of the four, and any provider that answers it — or CustomerContent —
// for all four fails at least two rows.

table 60967 "ALT DC Inheritance Fix"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            // Silent. The table declares SystemMetadata.
        }
        field(2; "Own Classification"; Text[30])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Payload"; Blob)
        {
            // Silent, and a Blob.
        }
        field(4; "Looked Up"; Text[30])
        {
            // Silent, and a FlowField — nothing about it is stored.
            FieldClass = FlowField;
            CalcFormula = lookup("ALT DC Inheritance Fix"."Own Classification" where("Entry No." = field("Entry No.")));
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
