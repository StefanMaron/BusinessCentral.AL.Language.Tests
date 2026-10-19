// @expect AL0195 | Invalid permission kind. Expected: 'X'
// AccessByPermission on a page field names a codeunit with RIMD: only X is allowed for a codeunit (corpus issue 669, writer CO).
table 50000 "MNC CO 1716 T"
{
    fields { field(1; Id; Integer) { } }
}

page 50001 "MNC CO 1716 P"
{
    SourceTable = "MNC CO 1716 T";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { AccessByPermission = codeunit "Sales-Post" = RIMD; }
        }
    }
}
