/// <summary>
/// Host rows for the Record Link (2000000068) tests. A dedicated fixture so the
/// <c>SetRange("Record ID", …)</c> filters in those tests can only ever see rows this
/// codeunit created — the Record Link table is tenant-wide and shared with every other
/// object in the database.
/// </summary>
table 60776 "ALT Link Host"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = CustomerContent; }
        field(2; Name; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
