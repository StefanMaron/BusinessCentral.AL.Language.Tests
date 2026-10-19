// Fixtures for TestDateTimeInitValue.Codeunit.al: the same two InitValue shapes, declared by
// tableextensions on Base Application tables, which ship precompiled, so the extension's field
// properties reach the service tier by a different route than a table compiled in this app.
// "Industry Group" and "Mailing Group" were picked because no other corpus test uses them: every
// Init() of an extended table evaluates these InitValues, so a heavily used table would put this
// claim in front of unrelated tests. Each shape gets its own table so one failing cannot hide the
// other.
// Written by agent stma-auto2-3 (AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4794).
tableextension 67512 "ALT DateTime Init Ext" extends "Industry Group"
{
    fields
    {
        field(67512; "ALT Ext Zero DateTime"; DateTime)
        {
            DataClassification = CustomerContent;
            InitValue = 0DT;
        }
    }
}

tableextension 67513 "ALT Closing Date Init Ext" extends "Mailing Group"
{
    fields
    {
        field(67513; "ALT Ext Closing Date"; Date)
        {
            DataClassification = CustomerContent;
            InitValue = C20260101D;
        }
    }
}
