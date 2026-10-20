// @expect AL0195 | Invalid permission kind. Expected: 'X'
// AccessByPermission on a page field names a page object with R: only X is allowed for a page (corpus issue 669, writer CO).
table 50000 "MNC CO 1715 T"
{
    fields { field(1; Id; Integer) { } }
}

page 50001 "MNC CO 1715 P"
{
    SourceTable = "MNC CO 1715 T";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { AccessByPermission = page "Customer List" = R; }
        }
    }
}
