// Source table for the lookup() FlowField below. Deliberately named as a
// SINGLE-WORD identifier (no spaces) — the exact shape that AL allows (and
// idiomatically prefers) UNQUOTED in a `lookup(TableName.Field where(...))`
// CalcFormula.
table 60228 FFLConfigLine
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ReportId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; TargetTableNo; Integer) { }
    }

    keys
    {
        key(PK; ReportId, LineNo) { Clustered = true; }
    }
}
