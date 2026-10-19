// @expect AL0132 | 'TestPage Customer List' does not contain a definition for 'Delete'
// @expect AL0132 | 'TestPage Customer List' does not contain a definition for 'DeleteRow'
// A TestPage has no method that deletes the current row (corpus issue 667, item 4; microsoft/AL issues 3253 and 7045).
codeunit 50622 "MNC CA 1602"
{
    procedure Probe()
    var
        Pg: TestPage "Customer List";
    begin
        Pg.OpenEdit();
        Pg.Delete();
        Pg.DeleteRow();
    end;
}
