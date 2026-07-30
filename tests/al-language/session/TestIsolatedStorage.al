// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: none (IsolatedStorage is a global scope, no fixture table)
//
// IsolatedStorage Set/Contains/Get/Delete round-trip. Values must round-trip exactly and
// deletes must be observable; a missing key must report false, never throw.

codeunit 60378 "Test Isolated Storage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure IsolatedStorage_SetContainsGet_RoundTripsExactValue()
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsTrue(IsolatedStorage.Set('its-key', 'its-value'), 'IsolatedStorage.Set must return true.');
        Assert.IsTrue(IsolatedStorage.Contains('its-key'), 'IsolatedStorage.Contains must see the stored key.');
        Assert.IsTrue(IsolatedStorage.Get('its-key', Value), 'IsolatedStorage.Get must return true for a stored key.');
        Assert.AreEqual('its-value', Value, 'IsolatedStorage.Get must round-trip the exact value.');
    end;

    [Test]
    procedure IsolatedStorage_Delete_RemovesTheEntry()
    begin
        Initialize();

        IsolatedStorage.Set('its-doomed', 'x');
        Assert.IsTrue(IsolatedStorage.Delete('its-doomed'), 'IsolatedStorage.Delete must return true for an existing key.');
        Assert.IsFalse(IsolatedStorage.Contains('its-doomed'), 'Deleted key must not be contained.');
    end;

    [Test]
    procedure IsolatedStorage_EncryptDecrypt_RoundTripsAndIsNotPlaintext()
    var
        CipherText: Text;
    begin
        Initialize();

        Assert.IsTrue(EncryptionEnabled(), 'EncryptionEnabled must be true (in-process AES envelope).');
        CipherText := Encrypt('its-secret');
        Assert.AreNotEqual('its-secret', CipherText, 'Encrypt must not return the plaintext.');
        Assert.AreEqual('its-secret', Decrypt(CipherText), 'Decrypt must round-trip the exact plaintext.');
    end;

    [Test]
    procedure IsolatedStorage_SetEncrypted_GetRoundTripsPlaintext()
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsTrue(IsolatedStorage.SetEncrypted('its-enc-key', 'its-enc-value'), 'IsolatedStorage.SetEncrypted must return true.');
        Assert.IsTrue(IsolatedStorage.Get('its-enc-key', Value), 'IsolatedStorage.Get must find the encrypted entry.');
        Assert.AreEqual('its-enc-value', Value, 'Encrypted entry must round-trip to plaintext on Get.');
    end;

    [Test]
    procedure IsolatedStorage_Get_MissingKey_ReturnsFalse()
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsFalse(IsolatedStorage.Get('its-absent', Value), 'IsolatedStorage.Get must return false for a missing key.');
        Assert.IsFalse(IsolatedStorage.Contains('its-absent'), 'IsolatedStorage.Contains must be false for a missing key.');
    end;

    local procedure Initialize()
    begin
        // IsolatedStorage has no DeleteAll; each test uses its own unique keys, so no
        // cross-test cleanup is needed.
    end;
}
