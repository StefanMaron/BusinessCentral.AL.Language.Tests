// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: ALT Relation Parent (table 60028),
//                ALT Triggered Order Ext (tableextension 60024 over ALT Triggered 60002),
//                PXT List Ext (pageextension 60657 over PXT List),
//                EEM Status (enum 60880), EEM Status Ext (enumextension 60881 over EEM Status),
//                ALT Agg Perm Set (permissionset 60930)
// BC versions: 27.0+
//
// Pins AllObj's owning-app columns "App Package ID" (60) and "App Runtime Package ID" (61)
// for the object kinds that are not tables, pages, codeunits, reports, queries or xmlports:
// a tableextension, a pageextension, an enum, an enumextension and a permission set this app
// declares. Each one must carry the same two package ids as a table this app declares --
// they are one app's objects -- and those ids must not be empty.
//
// One test per kind on purpose: whether the platform fills these columns is decided per
// object kind, so a failure has to say which kind it is about.
//
// The control, AllObj_Get_BaseApplicationTable_PackageIdsDifferFromThisApp, keeps "equal to
// this app's table" from being satisfied by an implementation writing one constant into
// every row.
//
// AlRunner#4000: the runner left these kinds with empty package ids because it found the
// owner of a compiled object only through the emitted type name, and enums and permission
// sets emit no type.

codeunit 60989 "Test AllObj Owning App Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AllObj_Get_OwnTableExtension_PackageIdsAreThisApps()
    // CLAIM: a tableextension this app declares is owned by this app.
    var
        AllObj: Record AllObj;
    begin
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::TableExtension, 60024),
            'AllObj has no TableExtension row for ALT Triggered Order Ext (60024).');
        AssertOwnedByThisApp(AllObj, 'tableextension ALT Triggered Order Ext');
    end;

    [Test]
    procedure AllObj_Get_OwnPageExtension_PackageIdsAreThisApps()
    // CLAIM: a pageextension this app declares is owned by this app.
    var
        AllObj: Record AllObj;
    begin
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::PageExtension, 60657),
            'AllObj has no PageExtension row for PXT List Ext (60657).');
        AssertOwnedByThisApp(AllObj, 'pageextension PXT List Ext');
    end;

    [Test]
    procedure AllObj_Get_OwnEnum_PackageIdsAreThisApps()
    // CLAIM: an enum this app declares is owned by this app.
    var
        AllObj: Record AllObj;
    begin
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Enum, 60880),
            'AllObj has no Enum row for EEM Status (60880).');
        AssertOwnedByThisApp(AllObj, 'enum EEM Status');
    end;

    [Test]
    procedure AllObj_Get_OwnEnumExtension_PackageIdsAreThisApps()
    // CLAIM: an enumextension this app declares is owned by this app.
    var
        AllObj: Record AllObj;
    begin
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::EnumExtension, 60881),
            'AllObj has no EnumExtension row for EEM Status Ext (60881).');
        AssertOwnedByThisApp(AllObj, 'enumextension EEM Status Ext');
    end;

    [Test]
    procedure AllObj_Get_OwnPermissionSet_PackageIdsAreThisApps()
    // CLAIM: a permission set this app declares is owned by this app.
    var
        AllObj: Record AllObj;
    begin
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::PermissionSet, 60930),
            'AllObj has no PermissionSet row for ALT Agg Perm Set (60930).');
        AssertOwnedByThisApp(AllObj, 'permissionset ALT Agg Perm Set');
    end;

    [Test]
    procedure AllObj_Get_BaseApplicationTable_PackageIdsDifferFromThisApp()
    // CLAIM: another app's object carries that app's package ids, not this app's -- the
    // control against one constant written into every row.
    var
        AllObj: Record AllObj;
        OwnTable: Record AllObj;
        EmptyId: Guid;
    begin
        GetOwnTable(OwnTable);
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, 18),
            'AllObj has no Table row for Customer (18).');
        Assert.AreNotEqual(
            EmptyId, AllObj."App Runtime Package ID",
            'App Runtime Package ID of Customer must not be empty.');
        Assert.AreNotEqual(
            OwnTable."App Runtime Package ID", AllObj."App Runtime Package ID",
            'Customer must not carry this app''s App Runtime Package ID.');
        Assert.AreNotEqual(
            OwnTable."App Package ID", AllObj."App Package ID",
            'Customer must not carry this app''s App Package ID.');
    end;

    local procedure AssertOwnedByThisApp(var AllObj: Record AllObj; What: Text)
    var
        OwnTable: Record AllObj;
        EmptyId: Guid;
    begin
        GetOwnTable(OwnTable);
        Assert.AreNotEqual(
            EmptyId, AllObj."App Runtime Package ID",
            StrSubstNo('App Runtime Package ID of %1 must not be empty.', What));
        Assert.AreNotEqual(
            EmptyId, AllObj."App Package ID",
            StrSubstNo('App Package ID of %1 must not be empty.', What));
        Assert.AreEqual(
            OwnTable."App Runtime Package ID", AllObj."App Runtime Package ID",
            StrSubstNo('%1 must carry the same App Runtime Package ID as a table this app declares.', What));
        Assert.AreEqual(
            OwnTable."App Package ID", AllObj."App Package ID",
            StrSubstNo('%1 must carry the same App Package ID as a table this app declares.', What));
    end;

    local procedure GetOwnTable(var OwnTable: Record AllObj)
    var
        EmptyId: Guid;
    begin
        Assert.IsTrue(
            OwnTable.Get(OwnTable."Object Type"::Table, Database::"ALT Relation Parent"),
            'AllObj has no Table row for ALT Relation Parent.');
        Assert.AreNotEqual(
            EmptyId, OwnTable."App Runtime Package ID",
            'App Runtime Package ID of a table this app declares must not be empty.');
    end;
}
