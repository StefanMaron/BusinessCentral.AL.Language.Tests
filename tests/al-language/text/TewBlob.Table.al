// Migrated from AL Runner tests/runner-extras/text-encoding-windows (TewSrc.al).
table 60856 "TEW Blob"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
