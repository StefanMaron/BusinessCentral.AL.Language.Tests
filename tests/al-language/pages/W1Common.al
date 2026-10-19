// Probe fixtures shared by the batch 1 page probes: one plain table.
table 69232 "W1 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Grp; Integer) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Amount) { }
        key(ByName; Name) { }
    }
}
