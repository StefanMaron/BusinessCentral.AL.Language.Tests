// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-joker-method
// Scope: in-scope
// Fixtures used: Test TestField LookupPage Row (60037)
//
// Backing table for the Record.TestField suite proving TestField's own error message is
// unaffected by whether (or how) the table's LookupPageId resolves. Declares LookupPageId so
// a record of this type carries the same table-metadata shape TestField reads a "navigate to
// related record" convenience action from — without that action's resolution being able to
// change what TestField actually reports.

table 60037 "Test TestField LookupPage Row"
{
    DataClassification = CustomerContent;
    Caption = 'Test TestField LookupPage Row';
    LookupPageId = "Test TestField LookupPage Card";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Mandatory Field"; Text[30])
        {
            Caption = 'Mandatory Field';
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
