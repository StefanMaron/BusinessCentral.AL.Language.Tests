table 60229 "FFL Field Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ReportId; Integer) { }
        field(2; ConfigLineNo; Integer) { }
        field(3; LineNo; Integer) { }
        // Mirrors Pageworks' PageworksDSFieldMapLine.TargetTableNo exactly:
        // `lookup(PageworksDSFieldConfigLine.TargetTableNo where(...))` — an
        // UNQUOTED single-word source table name (FFLConfigLine, no spaces).
        field(50; TargetTableNo; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup(FFLConfigLine.TargetTableNo where(ReportId = field(ReportId), LineNo = field(ConfigLineNo)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; ReportId, ConfigLineNo, LineNo) { Clustered = true; }
    }
}
