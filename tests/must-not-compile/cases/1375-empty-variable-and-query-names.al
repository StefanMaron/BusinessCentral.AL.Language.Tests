// @expect AL0855 | The variable name cannot be empty.
// @expect AL0155 | A member of type QueryColumn with name '' is already defined in Query 'MNC BM Q1375'
// @expect AL0379 | The name '' cannot be used as an identifier because it does not comply with the Common Language Specification
// @expect AL0155 | A member of type QueryDataItem with name '' is already defined in Query 'MNC BM Q1375'
// @expect AL0379 | The name '' cannot be used as an identifier because it does not comply with the Common Language Specification
// Corpus #664 item 13. A variable named "" is AL0855. A query data item and a column named "" give AL0155 and AL0379 each.
// A table field or key named "" is only warning AL0912 (an error from runtime 30.0), and a codeunit named "" compiles with no diagnostic (AL 30.0 beta compiler).
query 51375 "MNC BM Q1375"
{
    elements
    {
        dataitem(""; Customer)
        {
            column(""; "No.") { }
        }
    }
}
codeunit 51375 "MNC BM C1375"
{
    procedure P()
    var
        "": Integer;
    begin
        "" := 1;
    end;
}
