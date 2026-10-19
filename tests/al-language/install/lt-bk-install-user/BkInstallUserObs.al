// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: none
//
// What the session user looks like from inside this app's own install triggers (corpus #376).
// Written by "LT BK Install User Recorder" (81750), read back by "LT BK Install User" (81751).
// Not per company: the key holds the trigger and the company, so a tier with several companies
// writes one row per company and the per-database trigger writes one row with a blank company.
table 81750 "LT BK Install User Obs"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "Trigger"; Code[20]) { }
        field(2; "Company"; Text[30]) { }
        field(3; "User Id"; Text[250]) { }
        field(4; "Sec Id Is Null"; Boolean) { }
        field(5; "User Row Found"; Boolean) { }
        field(6; "User Row Name"; Text[250]) { }
        field(7; "Is Super"; Boolean) { }
        field(8; "Access Control Rows"; Integer) { }
        field(9; "Super Rows"; Integer) { }
        field(10; "Client Type"; Text[50]) { }
        field(11; "Exec Ctx"; Text[30]) { }
        field(12; "Error Text"; Text[250]) { }
        field(13; "User Table Rows"; Integer) { }
    }

    keys
    {
        key(PK; "Trigger", "Company") { Clustered = true; }
    }
}
