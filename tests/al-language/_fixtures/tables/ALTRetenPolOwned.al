// A table this test app owns, used only as the subject of a module-ownership check.
// It is never on any platform's retention-policy allowed list until this app puts it there,
// on any BC version, which is what makes TestModuleOwnsOwnTable's before/after pair decisive.
table 60404 "ALT Reten Pol Owned"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; "Logged At"; DateTime) { DataClassification = SystemMetadata; }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}
