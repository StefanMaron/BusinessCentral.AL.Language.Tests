// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036 (shared by the other P84 files)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own row table used by the P84 reports and pages
// BC versions: 29 (27 and 28 by CI)

table 73036 "LT P84 Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Id'; }
        field(2; Name; Text[30]) { Caption = 'Name'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
