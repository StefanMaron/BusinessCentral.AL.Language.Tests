// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-retention-policies
//   dev-itpro/developer/methods-auto/navapp/navapp-getcallermoduleinfo-method
// Scope: in-scope
// Fixtures used: ALT Reten Pol Owned (60404) — a table this app owns and nothing else does.
// Note: an app may register ITS OWN table on the retention-policy allowed list. The System
//   Application decides that by asking NavApp.GetCallerModuleInfo who is calling and then
//   looking that module up in the platform's own list of published applications, so this is
//   also the observable end of "a platform knows which app owns which object".
// BC versions: 24+

codeunit 60405 "Test Module Owns Own Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AppCanRegisterItsOwnTableOnTheAllowedList()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        AltRetenPolOwned: Record "ALT Reten Pol Owned";
    begin
        // [GIVEN] A table this app owns, which no platform app has registered.
        Assert.IsFalse(
            RetenPolAllowedTables.IsAllowedTable(Database::"ALT Reten Pol Owned"),
            'The test app''s own table must not already be on the retention-policy allowed list.');

        // [WHEN] This app registers it, naming one of its own DateTime fields.
        // [THEN] The platform accepts it — the caller is the module that owns the table.
        Assert.IsTrue(
            RetenPolAllowedTables.AddAllowedTable(
                Database::"ALT Reten Pol Owned", AltRetenPolOwned.FieldNo("Logged At")),
            'AddAllowedTable must accept a table owned by the calling app.');

        // [THEN] And the registration is readable back.
        Assert.IsTrue(
            RetenPolAllowedTables.IsAllowedTable(Database::"ALT Reten Pol Owned"),
            'IsAllowedTable must report the table this app just registered.');
        Assert.AreEqual(
            AltRetenPolOwned.FieldNo("Logged At"),
            RetenPolAllowedTables.GetDefaultDateFieldNo(Database::"ALT Reten Pol Owned"),
            'The registered default date field number must be the one that was passed in.');
    end;

    [Test]
    procedure AppCannotRegisterATableItDoesNotOwn()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // The negative half, and it is what stops the test above passing for the wrong reason:
        // a platform that answered "yes, you own it" to every module would accept this too.
        // AllObjWithCaption (2000000058) is a platform table this app plainly does not own.
        Assert.IsFalse(
            RetenPolAllowedTables.AddAllowedTable(Database::AllObjWithCaption, 0),
            'AddAllowedTable must refuse a table the calling app does not own.');
        Assert.IsFalse(
            RetenPolAllowedTables.IsAllowedTable(Database::AllObjWithCaption),
            'A refused table must not appear on the allowed list.');
    end;
}
