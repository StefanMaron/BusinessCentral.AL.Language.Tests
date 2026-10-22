// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// A bare call of an unknown procedure inside a report trigger.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Report"
{
    dataset { dataitem(Row; "MNC Table") { column(Id; Id) { } } }

    trigger OnPreReport()
    begin
        NoSuchProcedure();
    end;
}
