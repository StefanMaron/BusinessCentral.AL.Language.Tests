// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-joker-method
// Scope: in-scope
// Fixtures used: Test TestField LookupPage Row (60037), Test TestField LookupPage Card (60038)
//
// Record.TestField's error message is built purely from the field caption, the table
// caption, and the primary key string — never from the table's LookupPageId property (a
// table-metadata detail unrelated to the message text). This pins that: TestField on a table
// that DOES declare LookupPageId still raises the exact, unmodified message.

codeunit 60039 "Test TestField LookupPageId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test TestField LookupPage Row";
    begin
        Row.DeleteAll();
    end;

    // Positive: a populated mandatory field passes TestField without error, and the value is
    // left unchanged — a stub implementation that always throws would fail this.
    [Test]
    procedure TestField_PopulatedMandatoryField_Succeeds()
    var
        Row: Record "Test TestField LookupPage Row";
    begin
        Initialize();
        Row.Init();
        Row.Code := 'XYZ';
        Row."Mandatory Field" := 'Populated';
        Row.Insert();

        Row.TestField("Mandatory Field");

        Assert.AreEqual('Populated', Row."Mandatory Field", 'TestField must not alter a populated field');
    end;

    // Negative: an empty mandatory field raises the exact "must have a value" message —
    // field caption, table caption, and primary key, unaffected by the table's LookupPageId.
    // A stub that always threw a generic error, or one whose text was hijacked by trying (and
    // failing) to resolve the LookupPageId's navigate action, would both fail this exact-text
    // assertion while a weaker "some error was raised" check would not catch either.
    [Test]
    procedure TestField_EmptyMandatoryField_RaisesExactMessage()
    var
        Row: Record "Test TestField LookupPage Row";
    begin
        Initialize();
        Row.Init();
        Row.Code := 'ABC';
        Row."Mandatory Field" := '';
        Row.Insert();

        asserterror Row.TestField("Mandatory Field");

        Assert.ExpectedError(
            'Mandatory Field must have a value in Test TestField LookupPage Row: Code=ABC. It cannot be zero or empty.');
    end;
}
