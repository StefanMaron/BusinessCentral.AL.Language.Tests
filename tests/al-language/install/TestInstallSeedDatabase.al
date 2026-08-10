// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-triggers
// Scope: in-scope
// Fixtures used: none
//
// Target table for the per-DATABASE install-trigger seed row. The Subtype=Install
// codeunit (Install Seeder, 60618) inserts here from OnInstallAppPerDatabase, which
// fires once, globally, BEFORE any company context exists — a per-company table
// (the AL default) rejects that write with "You must choose a company...", so this
// table is intentionally global (DataPerCompany = false).

table 60621 "Install Seed Database"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

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
