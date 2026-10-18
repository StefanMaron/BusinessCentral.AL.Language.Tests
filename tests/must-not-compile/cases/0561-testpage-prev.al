// @expect AL0666 | 'Prev' is not available in runtime version '16.0'.
// TestPage.Prev only exists in runtime versions 3.0 until 13.0 (Previous() is the method of runtime 16.0).
codeunit 50561 "MNC O 0561"
{
    procedure Probe()
    var Pg: TestPage "Customer List";
    begin
        Pg.Prev();
    end;
}
