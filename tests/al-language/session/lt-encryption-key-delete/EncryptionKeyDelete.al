// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-deleteencryptionkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74897
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: DeleteEncryptionKey and the state it leaves: EncryptionEnabled() and EncryptionKeyExists() before and after, DeleteEncryptionKey with no key present
//   (does it raise, error text and code), with a key present (CreateEncryptionKey first, only when the database has none, so the database ends as it began),
//   and a second DeleteEncryptionKey right after the first.
//   The test that creates a key runs only when the database had none at the start, and always deletes the key again.
// BC versions: all (CI)

codeunit 74897 "LT Encryption Key Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure State_AtStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('enabled', Format(EncryptionEnabled()));
        Observer.Observe('keyExists', Format(EncryptionKeyExists()));
        Observer.Finish();
    end;

    [Test]
    procedure Delete_WithoutKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if EncryptionKeyExists() then begin
            Observer.Observe('skipped', 'key exists');
            Observer.Finish();
            exit;
        end;
        asserterror DeleteEncryptionKey();
        Observer.ObserveError('deleteNoKey');
        Observer.Observe('enabledAfter', Format(EncryptionEnabled()));
        Observer.Observe('keyExistsAfter', Format(EncryptionKeyExists()));
        Observer.Finish();
    end;

    [Test]
    procedure Delete_WithKey_ThenAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if EncryptionKeyExists() then begin
            Observer.Observe('skipped', 'key exists');
            Observer.Finish();
            exit;
        end;
        CreateEncryptionKey();
        Observer.Observe('enabledWithKey', Format(EncryptionEnabled()));
        Observer.Observe('keyExistsWithKey', Format(EncryptionKeyExists()));
        DeleteEncryptionKey();
        Observer.Observe('enabledAfterDelete', Format(EncryptionEnabled()));
        Observer.Observe('keyExistsAfterDelete', Format(EncryptionKeyExists()));
        asserterror DeleteEncryptionKey();
        Observer.ObserveError('deleteTwice');
        Observer.Observe('keyExistsEnd', Format(EncryptionKeyExists()));
        Observer.Finish();
    end;
}
