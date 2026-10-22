// @expect AL0132 | 'Row' does not contain a definition for 'SetRange'
// @expect AL0132 | 'Row' does not contain a definition for 'GetRangeMin'
// @expect AL0132 | 'Row' does not contain a definition for 'GetRangeMax'
// A data item of a TestRequestPage (TestFilter) has SetFilter and GetFilter, but no SetRange, GetRangeMin or GetRangeMax (corpus issue 646, item 10).
report 51120 "MNC AQ Report 51120"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer) { }
    }
}

codeunit 51121 "MNC AQ Test 51121"
{
    Subtype = Test;

    [RequestPageHandler]
    procedure Handler(var RP: TestRequestPage "MNC AQ Report 51120")
    var
        Value: Text;
    begin
        RP.Row.SetRange(1, 2);
        Value := RP.Row.GetRangeMin();
        Value := RP.Row.GetRangeMax();
    end;
}
