// Fixture for TestFieldDataClassificationVirtualTable.al.
//
// Every field declares a DIFFERENT DataClassification, and one of the four is the table-level
// default rather than a field-level declaration, so a provider that answered every row with
// one constant — the table's own DataClassification, say — fails on three of the four rows.
// Field 5 carries a TableRelation so the relation columns have something non-zero to report
// next to a field that has none.

table 60965 "ALT Field Classification Fix"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "End User Identifiable"; Text[30])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Account Data"; Text[30])
        {
            DataClassification = AccountData;
        }
        field(4; "System Metadata"; Text[30])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Universal Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "ALT Universal"."Entry No.";
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(ByAccountData; "Account Data")
        {
        }
    }
}
