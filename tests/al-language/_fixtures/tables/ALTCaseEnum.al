// ALTCaseEnum: a table declaring the SAME enum type three times, once per keyword
// capitalization AL accepts — `Enum`, `enum`, `ENUM`.
//
// AL keywords are case-insensitive, so all three fields are the same declaration written
// three ways and must carry identical enum metadata. Nothing else in the corpus declares a
// field type in anything but the canonical capitalization, so nothing else can tell a
// consumer that reads the source spelling apart from one that reads the resolved type.
//
// "ALT Status" is reused rather than a new enum declared: the claim is about the TYPE
// KEYWORD, so holding the enum itself fixed is what makes the three fields comparable.
table 60505 "ALT Case Enum"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Canonical Case"; Enum "ALT Status")
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Lower Case"; enum "ALT Status")
        {
            DataClassification = SystemMetadata;
        }
        field(12; "Upper Case"; ENUM "ALT Status")
        {
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
