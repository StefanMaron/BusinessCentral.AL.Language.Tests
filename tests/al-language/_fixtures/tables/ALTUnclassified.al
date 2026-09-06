// ALTUnclassified: a table that declares NO table-level DataClassification property.
//
// It exists so Table Metadata (2000000136) can be asked what a real BC service tier reports
// in the DataClassification column for a table whose declaration is silent about it. Every
// other fixture this corpus points at that column -- ALT Relation Parent (SystemMetadata) and
// Install Seed Database (CustomerContent) -- states the property explicitly, so none of them
// exercises the undeclared case at all.
//
// DO NOT ADD `DataClassification` TO THIS TABLE. The absence of the property is the entire
// fixture; adding it silently turns the assertion in TestTableMetadataVirtualTable.al into a
// second copy of a case that is already covered twice.
//
// The FIELD does declare DataClassification = SystemMetadata, deliberately, and that is not an
// oversight: it follows the convention every other fixture table here uses, and it makes the
// experiment sharper rather than blunter. SystemMetadata is neither of the two candidate
// answers for the table-level default, so a service tier reporting SystemMetadata for the
// table would be saying something specific and legible -- that the table column is derived
// from the fields -- instead of coinciding with the answer under test.
table 60837 "ALT Unclassified"
{
    Caption = 'ALT Unclassified';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
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
