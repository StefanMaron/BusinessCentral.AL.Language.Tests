// Fixture for TestFieldEnumTypeVirtualTable.al.
//
// One field typed by an AL enum, one Option field declaring its own OptionMembers, and one
// field of neither kind. The three together separate "this field names an enum object" from
// "this field has options" from "this field has neither" — a provider answering a constant
// fails at least one of the three whichever constant it picks.

table 60470 "ALT Field Enum Type Fix"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Kind"; Enum "ALT Field Enum Kind") { }
        field(3; "Plain Option"; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
        }
        field(4; "Description"; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
