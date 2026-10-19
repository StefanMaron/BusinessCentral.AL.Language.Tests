/// <summary>
/// A host table that is NOT per company, for the Record Link column tests: the platform
/// writes and reads the Record Link "Company" column only for a per-company parent table.
/// </summary>
table 67680 "ALT Link Host No Company"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
