// @expect AL0192 | The return value must be used for the method 'OK'
// @expect AL0192 | The return value must be used for the method 'Cancel'
// TestPage.OK() and Cancel() return a TestAction; a plain statement that drops it does not compile (corpus issue 667, item 15).
// Holding it in a Variant compiles and does not close the page: pages/lt-ca-odd-667/CaTestPageTests.al.
codeunit 50621 "MNC CA 1601"
{
    procedure Probe()
    var
        Pg: TestPage "Customer List";
    begin
        Pg.OpenView();
        Pg.OK();
        Pg.Cancel();
    end;
}
