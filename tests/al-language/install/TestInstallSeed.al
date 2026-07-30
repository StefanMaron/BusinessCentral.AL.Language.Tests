// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-triggers
// Scope: in-scope
// Fixtures used: none
//
// Target table for install-trigger seeding. The Subtype=Install codeunit
// (Install Seeder, 60618) inserts rows here from its lifecycle triggers; the
// tests assert the exact rows exist BEFORE any test code runs.

table 60617 "Install Seed"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Value"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
