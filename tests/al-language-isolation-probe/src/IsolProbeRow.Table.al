namespace ALLanguage.IsolationProbe;

// The database observable for "Isol Probe Fixture" (61302). Test 1 inserts a row; test 5
// looks for it. Only this app's fixture touches the table.
table 61300 "Isol Probe Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}
