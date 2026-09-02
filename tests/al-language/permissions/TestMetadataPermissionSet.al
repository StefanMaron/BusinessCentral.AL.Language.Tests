// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope (reads a platform virtual table; no fixtures needed)
// BC versions: 27.5+
//
// The "Metadata Permission Set" virtual table (2000000250) is how AL discovers the
// permission sets the installed apps declare. Microsoft's own
// "Users - Create Super User" (codeunit 9000) reads it to find the SUPER role before
// it can create a user, so a large part of the Base Application test corpus depends
// on what this table answers.
//
// These tests pin four things the table's shape is easy to get subtly wrong:
//   - SUPER and SECURITY carry an ALL-ZERO "App ID" even though an app declares them.
//   - "Role ID" is the permission set OBJECT NAME, and "Name" is its Caption -- two
//     different strings, not one repeated.
//   - "App ID" is really part of the primary key, so SUPER is not reachable under
//     some other app's id.
//   - "Assignable" carries both values, and every listed permission set carries a
//     non-blank Name.
codeunit 60290 "Test Metadata Perm. Set"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        SuperRoleTok: Label 'SUPER', Locked = true;
        SecurityRoleTok: Label 'SECURITY', Locked = true;

    [Test]
    procedure MetadataPermissionSet_Super_IsFoundUnderTheNullAppId()
    // CLAIM: SUPER is reachable at the primary key (<null guid>, 'SUPER') -- the exact
    // lookup codeunit 9000's GetSuperRole performs -- and its Name is the platform's own
    // caption for that role, not the role id repeated back.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        NullAppId: Guid;
    begin
        Initialize();
        MetadataPermissionSet.Get(NullAppId, SuperRoleTok);

        Assert.AreEqual(SuperRoleTok, MetadataPermissionSet."Role ID", 'Role ID of the fetched row');
        Assert.AreEqual('This role has all permissions.', MetadataPermissionSet.Name, 'Name is the permission set Caption, not its Role ID');
        Assert.IsTrue(MetadataPermissionSet.Assignable, 'SUPER must be assignable');
        Assert.AreEqual(NullAppId, MetadataPermissionSet."App ID", 'SUPER carries an all-zero App ID');
    end;

    [Test]
    procedure MetadataPermissionSet_Security_AlsoCarriesTheNullAppId()
    // CLAIM: SECURITY is the second role the platform blanks the App ID of. Getting it
    // under the null guid must succeed for the same reason SUPER does -- so this is not
    // a one-off special case for the string 'SUPER'.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        NullAppId: Guid;
    begin
        Initialize();
        MetadataPermissionSet.Get(NullAppId, SecurityRoleTok);

        Assert.AreEqual(SecurityRoleTok, MetadataPermissionSet."Role ID", 'Role ID of the fetched row');
        Assert.AreEqual(NullAppId, MetadataPermissionSet."App ID", 'SECURITY carries an all-zero App ID');
    end;

    [Test]
    procedure MetadataPermissionSet_AppDeclaredRole_CarriesItsOwningAppId()
    // CLAIM: a permission set that is NOT one of the two platform roles carries the id of
    // the app that declares it, and its Name is that set's declared Caption. This is the
    // counterexample to the two tests above: the null App ID is a rule about SUPER and
    // SECURITY, not the column's only value.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        NullAppId: Guid;
    begin
        Initialize();
        MetadataPermissionSet.SetRange("Role ID", 'D365 BASIC');
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'Base Application declares the D365 BASIC permission set');

        Assert.AreNotEqual(NullAppId, MetadataPermissionSet."App ID", 'an app-declared role carries its owning app id');
        Assert.AreEqual('Dynamics 365 Basic access', MetadataPermissionSet.Name, 'Name is the declared Caption');
    end;

    [Test]
    procedure MetadataPermissionSet_AppIdIsPartOfThePrimaryKey()
    // CLAIM: "App ID" really participates in the key. Asking for SUPER under some other
    // app id must NOT find the row that lives under the null guid -- an implementation
    // that keyed on the Role ID alone would wrongly return it.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        ForeignAppId: Guid;
    begin
        Initialize();
        ForeignAppId := CreateGuid();

        asserterror MetadataPermissionSet.Get(ForeignAppId, SuperRoleTok);
        Assert.ExpectedErrorCannotFind(Database::"Metadata Permission Set");
    end;

    [Test]
    procedure MetadataPermissionSet_UnknownRole_GetRaisesRecordNotFound()
    // CLAIM: an undeclared role id is not invented. The table answers only for permission
    // sets the installed apps really declare.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        NullAppId: Guid;
    begin
        Initialize();
        asserterror MetadataPermissionSet.Get(NullAppId, 'ALT NO SUCH ROLE');
        Assert.ExpectedErrorCannotFind(Database::"Metadata Permission Set");
    end;

    [Test]
    procedure MetadataPermissionSet_ListsEveryInstalledAppsPermissionSets()
    // CLAIM: the table is the full inventory, not just the roles the platform needs.
    // A Base Application + System Application install declares hundreds; asserting a
    // floor well above the handful named in these tests rules out an implementation
    // that only knows the rows some other test asked for.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        Initialize();
        Assert.IsTrue(MetadataPermissionSet.Count() > 50, 'a Base Application install declares far more than 50 permission sets');
    end;

    [Test]
    procedure MetadataPermissionSet_AssignableCarriesBothValues()
    // CLAIM: Assignable is read from each permission set's own declaration -- there are
    // both assignable and non-assignable ones, and filtering on the column really selects.
    // An implementation hardcoding either value fails one half of this.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        Initialize();
        MetadataPermissionSet.SetRange(Assignable, true);
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'at least one assignable permission set exists');
        Assert.IsTrue(MetadataPermissionSet.Assignable, 'a row returned under SetRange(Assignable, true) is assignable');

        MetadataPermissionSet.Reset();
        MetadataPermissionSet.SetRange(Assignable, false);
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'at least one non-assignable permission set exists');
        Assert.IsFalse(MetadataPermissionSet.Assignable, 'a row returned under SetRange(Assignable, false) is not assignable');
    end;

    [Test]
    procedure MetadataPermissionSet_EveryListedRoleCarriesAName()
    // CLAIM: every permission set the table lists carries a non-blank Name.
    //
    // An earlier version of this test asserted the opposite -- that a permission set
    // declaring no Caption is listed with a BLANK Name, so a row with an empty Name
    // must be findable. Every BC version from 27.0 to 28.4 refused that: FindFirst
    // under SetRange(Name, '') returns false, so no listed permission set has an
    // empty Name. The assertion below is the measured statement.
    //
    // What this test deliberately does NOT claim: WHY no Name is blank. Either BC
    // substitutes something (the Role ID) when a permission set declares no Caption,
    // or every permission set in a stock installation happens to declare one. No
    // service tier has been asked to distinguish those, so neither is asserted here.
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        Initialize();
        MetadataPermissionSet.SetRange(Name, '');
        Assert.IsFalse(
            MetadataPermissionSet.FindFirst(),
            'no permission set is listed with a blank Name');

        MetadataPermissionSet.Reset();
        Assert.IsTrue(MetadataPermissionSet.FindFirst(), 'the table lists at least one permission set');
        Assert.AreNotEqual('', MetadataPermissionSet.Name, 'the first listed permission set carries a Name');
        Assert.AreNotEqual('', MetadataPermissionSet."Role ID", 'and it carries its Role ID');
    end;

    local procedure Initialize()
    begin
        // Nothing this codeunit touches is writable -- 2000000250 is a read-only
        // platform virtual table -- but the shared cleanup keeps the codeunit's entry
        // point identical to every other suite in this repo.
        Cleanup.Initialize();
    end;
}
