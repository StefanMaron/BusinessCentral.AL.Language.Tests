// @expect AL0133 | Argument 1: cannot convert from 'RecordRef' to 'Table'
// RecordRef.GetTable takes a Record; a RecordRef argument is rejected (a Variant that holds a RecordRef compiles: record/lt-as-records/AsRecRefGetTable.al).
table 51140 "MNC AS T1140"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 51141 "MNC AS C1140"
{
    procedure Probe()
    var
        A: RecordRef;
        B: RecordRef;
    begin
        A.Open(Database::"MNC AS T1140");
        B.GetTable(A);
    end;
}
