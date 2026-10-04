// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019)
//
// CLAIM OF THIS CODEUNIT: RecordRef.Open on a table id that no installed app declares raises
// an AL error that asserterror catches and GetLastErrorText reads back. (PROBE: the text is
// measured by the CI run, not assumed.)

codeunit 69900 "Test RecordRef Open Missing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_Open_MissingTable_BareAsserterror_IsCaught()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        asserterror RecRef.Open(99991);

        Assert.AreNotEqual('', GetLastErrorText(), 'asserterror must have caught an error from RecordRef.Open of a missing table');
    end;

    [Test]
    procedure RecordRef_Open_MissingTable_ErrorText()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        asserterror RecRef.Open(99991);

        Assert.AreEqual('PROBE', GetLastErrorText(), 'PROBE: the error text BC raises');
    end;

    [Test]
    procedure RecordRef_Open_ExistingTable_StillOpens()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(60000);

        Assert.AreEqual(60000, RecRef.Number, 'RecordRef.Open(60000) must open the declared table');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
