// Fixture for "OKP Ok Part Row Tests" (60760): the header a card shows, keyed on one field.
table 60760 "OKP Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
