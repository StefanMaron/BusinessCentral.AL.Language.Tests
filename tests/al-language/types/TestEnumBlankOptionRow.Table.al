// Support table for TestEnumBlankOptionFilterTests.Codeunit.al.
//
// Two Option fields that differ only in how their ordinal-0 member is spelled:
// "Space Blank" names it with a single space (the spelling AL uses for a blank
// enum member, `value(0; " ")`), "Empty Blank" leaves the name genuinely empty.
// BC's option-text matcher skips zero-length member names, so the two must not
// answer the same way to the empty-string filter.
table 60301 "EBF Option Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Space Blank"; Option)
        {
            OptionMembers = " ",Draft,Active;
            DataClassification = SystemMetadata;
        }
        field(3; "Empty Blank"; Option)
        {
            OptionMembers = ,Draft,Active;
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
