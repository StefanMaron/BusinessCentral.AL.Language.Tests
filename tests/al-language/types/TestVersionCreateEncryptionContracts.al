// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/version/version-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-encrypt-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68970
// Probe: written against a real BC 27.5 service tier started by bc-linux, where an encryption key exists; every
// literal below is what that tier produced. Other BC versions and hosts were not measured.
//
// Pins:
//  - Version.Create(Major, Minor [, Build [, Revision]]) with missing parts reads 0 for them (Create(1, 2) is 1.2.0.0, build 0,
//    revision 0), Version.Create(Text) takes '1.2.3.4' and '1.2' (1.2.0.0); a text with one part, five parts or letters raises
//    "Could not parse string '<text>' into a version." / Argument; Format and ToText give 1.2.3.4; =, <>, <, >, <= compare the
//    parts left to right; an app's DataVersion is 1.0.0.0 here, the same as its AppVersion (not 0.0.0.0).
//  - Encryption, with the key this tier has (EncryptionEnabled and EncryptionKeyExists answer true): Encrypt('x') is a
//    text of 344 characters that differs from the input, differs on every call, decrypts to the input; Encrypt('') is
//    ''; Decrypt of a text that is not encrypted data raises "Unable to decrypt data. The data was encrypted using a
//    different key." / Encryption:Format.
// BC versions: 27.5

codeunit 68970 "Probe Version Encryption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure VersionCreate_MissingPartsAreZero_AndTextForms()
    var
        Ver: Version;
    begin
        Ver := Version.Create(1, 2);
        Assert.AreEqual('1.2.0.0', Format(Ver), 'Create(1, 2)');
        Assert.AreEqual(0, Ver.Build(), 'build');
        Assert.AreEqual(0, Ver.Revision(), 'revision');
        Ver := Version.Create(1, 2, 3);
        Assert.AreEqual('1.2.3.0', Format(Ver), 'Create(1, 2, 3)');
        Assert.AreEqual(3, Ver.Build(), 'build');
        Ver := Version.Create(1, 2, 3, 4);
        Assert.AreEqual('1.2.3.4', Ver.ToText(), 'ToText');
        Assert.AreEqual(1, Ver.Major(), 'Major');
        Assert.AreEqual(2, Ver.Minor(), 'Minor');
        Ver := Version.Create('1.2.3.4');
        Assert.AreEqual('1.2.3.4', Format(Ver), 'Create(text)');
        Ver := Version.Create('1.2');
        Assert.AreEqual('1.2.0.0', Format(Ver), 'Create(1.2)');
    end;

    [Test]
    procedure VersionCreate_BadText_RaisesAnArgumentError()
    var
        Ver: Version;
    begin
        asserterror Ver := Version.Create('1');
        Assert.AreEqual('Could not parse string ''1'' into a version.', GetLastErrorText(), 'one part');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'code');
        asserterror Ver := Version.Create('1.2.3.4.5');
        Assert.AreEqual('Could not parse string ''1.2.3.4.5'' into a version.', GetLastErrorText(), 'five parts');
        asserterror Ver := Version.Create('a.b');
        Assert.AreEqual('Could not parse string ''a.b'' into a version.', GetLastErrorText(), 'letters');
    end;

    [Test]
    procedure Version_Comparison_AndDataVersion()
    var
        Low: Version;
        High: Version;
        Same: Version;
        Info: ModuleInfo;
    begin
        Low := Version.Create(1, 2, 3, 4);
        High := Version.Create(1, 2, 3, 5);
        Same := Version.Create(1, 2, 3, 4);
        Assert.IsTrue(Low = Same, '=');
        Assert.IsTrue(Low <> High, '<>');
        Assert.IsTrue(Low < High, '<');
        Assert.IsFalse(Low > High, '>');
        Assert.IsTrue(Low <= Same, '<=');

        NavApp.GetCurrentModuleInfo(Info);
        Assert.AreEqual(Format(Info.AppVersion()), Format(Info.DataVersion()), 'DataVersion equals AppVersion');
        Assert.IsTrue(Info.DataVersion() <> Version.Create(0, 0, 0, 0), 'not 0.0.0.0');
    end;

    [Test]
    procedure Encryption_WithAKey_RoundTrips()
    var
        Encrypted: Text;
    begin
        Assert.IsTrue(EncryptionEnabled(), 'EncryptionEnabled');
        Assert.IsTrue(EncryptionKeyExists(), 'EncryptionKeyExists');

        Encrypted := Encrypt('x');

        Assert.AreEqual(344, StrLen(Encrypted), 'length');
        Assert.AreNotEqual('x', Encrypted, 'differs from the input');
        Assert.AreNotEqual(Encrypted, Encrypt('x'), 'differs on every call');
        Assert.AreEqual('x', Decrypt(Encrypted), 'round trip');
        Assert.AreEqual('', Encrypt(''), 'empty');
    end;

    [Test]
    procedure Decrypt_OfPlainText_RaisesAnEncryptionError()
    var
        Plain: Text;
    begin
        asserterror Plain := Decrypt('garbage');

        Assert.AreEqual('Unable to decrypt data. The data was encrypted using a different key.', GetLastErrorText(), 'text');
        Assert.AreEqual('Encryption:Format', GetLastErrorCode(), 'code');
    end;
}
