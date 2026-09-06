// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: ALT Relation Parent (60028), ALT Relation Parent B (60030),
//                ALT Event Mutation Control (codeunit 60030), ALT Captioned (60830),
//                ALT Card Page (60017)
// BC versions: 27.5+
//
// Pins the built-in "AllObj" (2000000038) and "AllObjWithCaption" (2000000058) system
// virtual tables: one row per compiled object, keyed on (Object Type, Object ID) and
// computed from the object's own metadata. Microsoft's own test libraries look table
// captions up through AllObjWithCaption, and this corpus's slim Assert carries a comment
// saying the lookup was dropped because the table "is a virtual platform table not visible
// to AL Runner v2's resolved dep set" -- a claim about a downstream consumer that nothing
// here adjudicated, because nothing here read either table at all.
//
// The discriminating test is AllObj_Get_SameObjectIdDifferentType_ReturnsDifferentObject:
// object id 60030 is BOTH a table and a codeunit in this app, with different names, so a
// provider keyed on the id alone -- or one answering a fixed row -- fails exactly one of
// the two halves.

codeunit 60802 "Test AllObj Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AllObj_Get_TableObject_ReturnsMatchingRow()
    // CLAIM: AllObj has a row for a compiled table, keyed on (Object Type::Table, id).
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, Database::"ALT Relation Parent"),
            'AllObj has no Table row for ALT Relation Parent.');

        Assert.AreEqual(
            'ALT Relation Parent', AllObj."Object Name",
            'Unexpected Object Name for the AllObj Table row of ALT Relation Parent.');
        Assert.AreEqual(
            Database::"ALT Relation Parent", AllObj."Object ID",
            'Unexpected Object ID for the AllObj Table row of ALT Relation Parent.');
        Assert.AreEqual(
            AllObj."Object Type"::Table, AllObj."Object Type",
            'The row fetched with Object Type::Table must report Object Type::Table.');
    end;

    [Test]
    procedure AllObj_Get_PageObject_ReturnsMatchingRow()
    // CLAIM: the same lookup works for a non-table object type.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Page, Page::"ALT Card Page"),
            'AllObj has no Page row for ALT Card Page.');

        Assert.AreEqual(
            'ALT Card Page', AllObj."Object Name",
            'Unexpected Object Name for the AllObj Page row of ALT Card Page.');
        Assert.AreEqual(
            AllObj."Object Type"::Page, AllObj."Object Type",
            'The row fetched with Object Type::Page must report Object Type::Page.');
    end;

    [Test]
    procedure AllObj_Get_SameObjectIdDifferentType_ReturnsDifferentObject()
    // CLAIM: the key is (Object Type, Object ID) -- the same id under two object types
    // resolves to two different objects.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // 60030 is table "ALT Relation Parent B"...
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, 60030),
            'AllObj has no Table row for object id 60030.');
        Assert.AreEqual(
            'ALT Relation Parent B', AllObj."Object Name",
            'Object id 60030 as a Table is ALT Relation Parent B.');

        // ...and 60030 is ALSO codeunit "ALT Event Mutation Control". Same id, different
        // object type, different name: an implementation that ignored Object Type, or that
        // answered a constant row, cannot satisfy both halves of this test.
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Codeunit, 60030),
            'AllObj has no Codeunit row for object id 60030.');
        Assert.AreEqual(
            'ALT Event Mutation Control', AllObj."Object Name",
            'Object id 60030 as a Codeunit is ALT Event Mutation Control.');
    end;

    [Test]
    procedure AllObj_Get_ObjectTypeThatDoesNotUseTheId_ReturnsFalse()
    // CLAIM: an id that exists under one object type is absent under another.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // 60028 is a table in this app, and no codeunit anywhere uses that id -- 50000..99999
        // is the partner range, so Microsoft ships nothing there either.
        Assert.IsTrue(
            AllObj.Get(AllObj."Object Type"::Table, 60028),
            'AllObj has no Table row for object id 60028.');
        Assert.IsFalse(
            AllObj.Get(AllObj."Object Type"::Codeunit, 60028),
            'No codeunit uses object id 60028, so AllObj must have no Codeunit row for it.');
    end;

    [Test]
    procedure AllObj_Get_UnknownObjectId_ReturnsFalse()
    // CLAIM: Get returns false for an id no object uses.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // Negative control for every positive test above: a provider answering every Get
        // with true would pass them all and fail here.
        Assert.IsFalse(
            AllObj.Get(AllObj."Object Type"::Table, 99999999),
            'AllObj must not have a row for an id no object uses.');
    end;

    [Test]
    procedure AllObj_SetRange_OnObjectTypeAndIdRange_SelectsOnlyMatchingRows()
    // CLAIM: filtering on Object Type and an Object ID range selects exactly the objects in
    // that range of that type.
    var
        AllObj: Record AllObj;
    begin
        Initialize();

        // Tables 60028, 60029 and 60030 are three consecutive fixture tables, so the count is
        // a concrete number rather than "more than zero".
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", 60028, 60030);
        Assert.AreEqual(3, AllObj.Count(), 'The Table rows for object ids 60028..60030 are exactly three.');

        // The same id range under Object Type::Codeunit selects only 60030, the one codeunit
        // in that span -- so the Object Type half of the filter is doing work.
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        Assert.AreEqual(1, AllObj.Count(), 'Exactly one codeunit is declared in the id range 60028..60030.');
        Assert.IsTrue(AllObj.FindFirst(), 'FindFirst must succeed for the one codeunit in the range.');
        Assert.AreEqual(
            'ALT Event Mutation Control', AllObj."Object Name",
            'The one codeunit in the id range 60028..60030 is ALT Event Mutation Control.');

        // And a range no object of that type occupies selects nothing.
        AllObj.SetRange("Object ID", 99999998, 99999999);
        Assert.AreEqual(0, AllObj.Count(), 'A range no object occupies must select no rows.');
        Assert.IsTrue(AllObj.IsEmpty(), 'IsEmpty must be true for a range no object occupies.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_CaptionedTable_ReportsDeclaredCaption()
    // CLAIM: AllObjWithCaption carries the object's caption alongside its name, and the two
    // are different strings when the object declares a Caption.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Captioned"),
            'AllObjWithCaption has no Table row for ALT Captioned.');

        // ALT Captioned exists precisely because its Caption and its Name differ, so a
        // provider echoing the name into the caption column cannot pass both assertions.
        Assert.AreEqual(
            'ALT Captioned', AllObjWithCaption."Object Name",
            'Object Name must read the object name of ALT Captioned.');
        Assert.AreEqual(
            'Captioned Fixture Table', AllObjWithCaption."Object Caption",
            'Object Caption must read the declared Caption of ALT Captioned, not its object name.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_SecondTable_ReportsItsOwnNameAndId()
    // CLAIM: AllObjWithCaption's columns vary per row rather than being constants.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Relation Parent B"),
            'AllObjWithCaption has no Table row for ALT Relation Parent B.');

        // A different row than the test above, read the same way.
        Assert.AreEqual(
            'ALT Relation Parent B', AllObjWithCaption."Object Name",
            'Unexpected Object Name for ALT Relation Parent B.');
        Assert.AreEqual(
            60030, AllObjWithCaption."Object ID",
            'ALT Relation Parent B is declared as table 60030.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_UnknownObjectId_ReturnsFalse()
    // CLAIM: Get returns false for an id no object uses.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsFalse(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, 99999999),
            'AllObjWithCaption must not have a row for an id no object uses.');
    end;

    local procedure Initialize()
    begin
        // AllObj and AllObjWithCaption are read-only system virtual tables -- nothing to
        // DeleteAll.
    end;
}
