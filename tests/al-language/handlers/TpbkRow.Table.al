// Fixture for TestPageBlankKeyInsert.al: a table whose OnInsert assigns the primary key when it
// is blank (the No. Series pattern, without Base Application).
table 60572 "TPBK Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[100]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Record "TPBK Log";
    begin
        if "No." = '' then
            "No." := 'AUTO1';
        Log.Note(Description);
    end;
}
