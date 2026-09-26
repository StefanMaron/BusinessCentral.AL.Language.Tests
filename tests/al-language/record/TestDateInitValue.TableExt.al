// Fixture for TestDateInitValue.Codeunit.al: the same Date InitValues, declared by a
// tableextension on a Base Application table (Job). The table itself ships precompiled in the
// Base Application package, so the extension's field properties reach the service tier by a
// different route than a table compiled in this app. Job is used only because it is always
// available; the claim is about where the InitValue was declared, not about Job.
// Written by agent stma-auto2-3 (AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4633).
tableextension 67510 "ALT Date Init Job Ext" extends Job
{
    fields
    {
        field(67510; "ALT Ext Start Date"; Date)
        {
            DataClassification = CustomerContent;
            InitValue = 20260101D;
        }
        field(67511; "ALT Ext Zero Date"; Date)
        {
            DataClassification = CustomerContent;
            InitValue = 0D;
        }
        field(67512; "ALT Ext Plain Date"; Date)
        {
            DataClassification = CustomerContent;
        }
    }
}
