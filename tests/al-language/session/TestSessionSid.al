// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-sid-method
// Scope: in-scope
//
// Sid() maps a Windows account name to its Windows security identifier. These
// tests pin down what BC returns when the name cannot be mapped to a Windows
// account at all, which is the normal case for a BC session user (the session
// user is an AAD/NavUserPassword identity, not a Windows account) and the case
// Microsoft's own test libraries hit when they call Sid(UserId).

codeunit 60933 "Test Session Sid"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Sid_UnmappableAccountName_ReturnsEmpty()
    // CLAIM: Sid() of a name that maps to no Windows account returns '' — it does
    // not throw, and it does not invent a SID.
    begin
        Initialize();

        Assert.AreEqual(
          '', Sid('ALTNOSUCHWINDOWSACCOUNT7F3A'),
          'Sid() of an unmappable Windows account name must return an empty string');
    end;

    [Test]
    procedure Sid_DomainQualifiedUnmappableName_ReturnsEmpty()
    // CLAIM: the same holds for a DOMAIN\account form, so the empty result is
    // about the identity not mapping, not about the name being unqualified.
    begin
        Initialize();

        Assert.AreEqual(
          '', Sid('ALTNODOMAIN7F3A\ALTNOSUCHWINDOWSACCOUNT7F3A'),
          'Sid() of an unmappable DOMAIN\account name must return an empty string');
    end;

    [Test]
    procedure Sid_CurrentUserId_ReturnsEmpty()
    // CLAIM: Sid(UserId) returns '' because the BC session user is not a Windows
    // account. This is the exact expression Microsoft's "Library - Document
    // Approvals".UserExists uses.
    begin
        Initialize();

        Assert.AreNotEqual('', UserId(), 'precondition: UserId() must be non-empty');
        Assert.AreEqual(
          '', Sid(UserId()),
          'Sid(UserId) must return an empty string — the session user is not a Windows account');
    end;

    [Test]
    procedure Sid_NoArgument_MatchesSidOfEmptyText()
    // CLAIM: the no-argument overload and Sid('') are the same call — both yield
    // the session user SID rather than attempting a name lookup.
    begin
        Initialize();

        Assert.AreEqual(
          Sid(), Sid(''),
          'Sid() and Sid('''') must return the same session-user SID');
    end;

    [Test]
    procedure Sid_NoArgument_ReturnsSessionSid()
    // CLAIM: the session user SID is empty in a Cloud session — there is no
    // Windows identity behind the session.
    begin
        Initialize();

        Assert.AreEqual(
          '', Sid(),
          'Sid() with no argument must return the session user SID');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
