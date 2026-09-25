// Fixture table behind "ONG Card" (60950) — see TestPageOpenNewAfterGetCurrRecord.al.
table 60950 "ONG Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        // Written only by the page's template step, never by the client, so a row carrying it
        // is the row that step inserted.
        field(3; "Made By Template"; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
