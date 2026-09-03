// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test GTR NonKeyRefresh Row (60045), Test GTR NonKeyRefresh List (60046)
//
// OBSERVATION PROBE (not yet a real assertion): what does GoToRecord's not-found path leave
// on the page's non-key field when the page was positioned on a row that is NOT the last row
// a forward not-found scan would visit? Row.Get('A') positions on the FIRST of three rows;
// GoToRecord for an absent key then runs a forward scan that visits A, B, C in that order.
// This test intentionally FAILS with an Error carrying the observed key + non-key field
// values, so the corpus CI log across all BC legs states what real BC does -- no assertion
// about the expected value is made here.

codeunit 60047 "Test GTR NonKeyRefresh Obs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRows()
    var
        Row: Record "Test GTR NonKeyRefresh Row";
    begin
        Row.DeleteAll();
        Row.Init(); Row."No." := 'A'; Row.Descr := 'Alpha'; Row.Insert();
        Row.Init(); Row."No." := 'B'; Row.Descr := 'Bravo'; Row.Insert();
        Row.Init(); Row."No." := 'C'; Row.Descr := 'Charlie'; Row.Insert();
    end;

    [Test]
    procedure Observe_NotFoundProbe_AfterPositioningOnFirstRow()
    var
        Row: Record "Test GTR NonKeyRefresh Row";
        Missing: Record "Test GTR NonKeyRefresh Row";
        TgrList: TestPage "Test GTR NonKeyRefresh List";
        Found: Boolean;
    begin
        SeedRows();

        Row.Get('A');
        Missing.Init();
        Missing."No." := 'ZZZ';
        Missing.Descr := 'Not inserted';

        TgrList.OpenView();
        TgrList.GoToRecord(Row);
        Found := TgrList.GoToRecord(Missing);

        Error('OBS found=%1 key=%2 desc=%3', Found, TgrList."No.".Value(), TgrList.Descr.Value());
    end;
}
