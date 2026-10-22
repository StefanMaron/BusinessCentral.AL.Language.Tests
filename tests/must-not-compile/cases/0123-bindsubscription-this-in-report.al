// @expect AL0133 | Argument 1: cannot convert from 'Report "MNC Report"' to 'Codeunit'
// BindSubscription(this) inside a report: this is a report, not a codeunit.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Report"
{
    dataset { dataitem(Row; "MNC Table") { } }

    trigger OnPreReport()
    begin
        BindSubscription(this);
    end;
}
