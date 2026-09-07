// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: ALT Relation Parent (60028), ALT Relation Parent B (60030),
//                ALT Event Mutation Control (codeunit 60030), ALT Captioned (60830),
//                ALT Card Page (60017), ALT List Page (60016),
//                ALT Profile RC SameApp (page 60904), Install Seeder (codeunit 60618),
//                Not An Installer (codeunit 60619), ALT CRM Entity (60291),
//                ALT Temp Only (60025), ALT Simple Report (60018)
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
//
// The AllObjWithCaption_..._ObjectSubtype... tests pin the "Object Subtype" column
// (field 30, AllObjWithCaption only -- AllObj has no such column). Its value is
// per-object-kind: a page reports its PageType, a codeunit its Subtype, a table its
// TableType, and a kind with no subtype concept reports the empty string. Each of those
// is asserted against at least two fixtures with DIFFERENT declared values, so an
// implementation answering one constant -- including the empty string every kind would
// otherwise take -- fails at least one half.
//
// The codeunit case carries two things worth pinning. First the asymmetry: a codeunit
// whose subtype is Normal reports the EMPTY string, while a table whose TableType is
// Normal reports the word 'Normal'. Second, a Subtype = Install codeunit ALSO reports the
// empty string -- not because Install is blanked, but because the AL compiler never writes
// Install into object metadata in the first place, so this column sees Normal. The
// sibling column asserts that same fact from the other side
// (Record_CodeunitMetadata_Get_InstallCodeunit_ReportsSubtypeNormal).

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

    [Test]
    procedure AllObjWithCaption_Get_Page_ObjectSubtypeIsThePageType()
    // CLAIM: for a Page row, Object Subtype carries the page's declared PageType, spelled
    // exactly as the AL PageType property is spelled.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // ALT Card Page declares PageType = Card.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Page::"ALT Card Page"),
            'AllObjWithCaption has no Page row for ALT Card Page.');
        Assert.AreEqual(
            'Card', AllObjWithCaption."Object Subtype",
            'Object Subtype of a PageType = Card page must be ''Card''.');

        // ALT List Page declares PageType = List. Two pages with DIFFERENT declared page
        // types, read the same way: an implementation answering one constant -- including
        // the empty string, or AL's default 'Card' for every page -- fails one of them.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, Page::"ALT List Page"),
            'AllObjWithCaption has no Page row for ALT List Page.');
        Assert.AreEqual(
            'List', AllObjWithCaption."Object Subtype",
            'Object Subtype of a PageType = List page must be ''List''.');
    end;

    [Test]
    procedure AllObjWithCaption_SetRange_ObjectSubtypeRoleCenter_FindsTheRoleCenterPage()
    // CLAIM: Object Subtype is a filterable column -- filtering Page rows to
    // Object Subtype = 'RoleCenter' selects role-center pages and excludes others. This
    // is the shape Base Application's own Role Center picker uses.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // Positive: the one RoleCenter page this app declares is reachable through the
        // filter, by name.
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');
        AllObjWithCaption.SetRange("Object ID", Page::"ALT Profile RC SameApp");
        Assert.IsTrue(
            AllObjWithCaption.FindFirst(),
            'Filtering Page rows to Object Subtype ''RoleCenter'' must find ALT Profile RC SameApp.');
        Assert.AreEqual(
            'ALT Profile RC SameApp', AllObjWithCaption."Object Name",
            'The RoleCenter-filtered row for that id is ALT Profile RC SameApp.');
        Assert.AreEqual(
            'RoleCenter', AllObjWithCaption."Object Subtype",
            'A row selected by Object Subtype = ''RoleCenter'' must report that subtype.');

        // Negative: the SAME filter over a Card page's id selects nothing, so the subtype
        // half of the filter is doing work rather than being ignored.
        AllObjWithCaption.SetRange("Object ID", Page::"ALT Card Page");
        Assert.IsTrue(
            AllObjWithCaption.IsEmpty(),
            'A PageType = Card page must not be selected by Object Subtype = ''RoleCenter''.');

        // ...and that same Card page IS selected once the subtype filter matches it, so the
        // emptiness above is the subtype filter and not a missing row.
        AllObjWithCaption.SetRange("Object Subtype", 'Card');
        Assert.IsTrue(
            AllObjWithCaption.FindFirst(),
            'ALT Card Page must be selected by Object Subtype = ''Card''.');
        Assert.AreEqual(
            'ALT Card Page', AllObjWithCaption."Object Name",
            'The Card-filtered row for that id is ALT Card Page.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Codeunit_ObjectSubtypeIsTheSubtypeAndEmptyForNormal()
    // CLAIM: for a Codeunit row, Object Subtype carries the subtype the AL COMPILER wrote
    // into object metadata -- and is the EMPTY string when that is Normal, rather than the
    // word 'Normal'.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // This very codeunit declares Subtype = Test, so it reads its own row. Subtype = Test
        // is carried into object metadata, unlike Install -- see the next test.
        Assert.IsTrue(
            AllObjWithCaption.Get(
                AllObjWithCaption."Object Type"::Codeunit, Codeunit::"Test AllObj Virtual Table"),
            'AllObjWithCaption has no Codeunit row for Test AllObj Virtual Table.');
        Assert.AreEqual(
            'Test', AllObjWithCaption."Object Subtype",
            'Object Subtype of a Subtype = Test codeunit must be ''Test''.');

        // Not An Installer declares no Subtype at all, so its subtype is Normal -- and BC
        // reports Normal as the empty string, not as 'Normal'. The pair is what makes this
        // discriminating: an implementation writing the subtype name unconditionally passes
        // the first half and fails here.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Codeunit::"Not An Installer"),
            'AllObjWithCaption has no Codeunit row for Not An Installer.');
        Assert.AreEqual(
            '', AllObjWithCaption."Object Subtype",
            'Object Subtype of a codeunit whose subtype is Normal must be the empty string.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_InstallCodeunit_ObjectSubtypeIsEmpty()
    // CLAIM: a Subtype = Install codeunit reports the EMPTY string here, not 'Install'.
    //
    // This is not the Normal-is-blanked rule reaching a second case -- it is a fact about
    // the AL COMPILER, one level upstream of this table. The compiler does not carry
    // Install into object metadata: NCLMetaCodeunit.Subtype reads the codeunit's
    // NavCodeunitOptionsAttribute, i.e. what the compiler wrote, and for an Install
    // codeunit that is Normal. AllObjWithCaption then blanks Normal, so the value lands on
    // the empty string by two steps rather than one.
    //
    // The sibling column asserts the same fact from the other side: CodeUnit Metadata
    // (2000000137) reports Subtype::Normal for an Install codeunit
    // (Record_CodeunitMetadata_Get_InstallCodeunit_ReportsSubtypeNormal). This test is why
    // an implementation cannot satisfy the Subtype = Test case above by simply echoing the
    // declared property.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Codeunit::"Install Seeder"),
            'AllObjWithCaption has no Codeunit row for Install Seeder.');
        Assert.AreEqual(
            '', AllObjWithCaption."Object Subtype",
            'A Subtype = Install codeunit reports the empty string: the compiler writes Normal.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Table_ObjectSubtypeIsTheTableType()
    // CLAIM: for a Table row, Object Subtype carries the declared TableType.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        // ALT CRM Entity declares TableType = CRM.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT CRM Entity"),
            'AllObjWithCaption has no Table row for ALT CRM Entity.');
        Assert.AreEqual(
            'CRM', AllObjWithCaption."Object Subtype",
            'Object Subtype of a TableType = CRM table must be ''CRM''.');

        // ALT Temp Only declares TableType = Temporary -- a different value, so the column
        // is read off the table rather than being a constant.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Temp Only"),
            'AllObjWithCaption has no Table row for ALT Temp Only.');
        Assert.AreEqual(
            'Temporary', AllObjWithCaption."Object Subtype",
            'Object Subtype of a TableType = Temporary table must be ''Temporary''.');

        // ALT Captioned declares no TableType, so its table type is Normal. Unlike a
        // codeunit's Normal subtype, a table's TableType is reported by NAME -- BC only
        // special-cases Normal for codeunits.
        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Database::"ALT Captioned"),
            'AllObjWithCaption has no Table row for ALT Captioned.');
        Assert.AreEqual(
            'Normal', AllObjWithCaption."Object Subtype",
            'Object Subtype of a table declaring no TableType must be ''Normal''.');
    end;

    [Test]
    procedure AllObjWithCaption_Get_Report_ObjectSubtypeIsEmpty()
    // CLAIM: object kinds that have no subtype concept report the EMPTY string, not some
    // placeholder. This is the negative control for every positive case above: an
    // implementation inventing a subtype for every kind fails here.
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();

        Assert.IsTrue(
            AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, Report::"ALT Simple Report"),
            'AllObjWithCaption has no Report row for ALT Simple Report.');
        Assert.AreEqual(
            '', AllObjWithCaption."Object Subtype",
            'A Report has no subtype, so Object Subtype must be the empty string.');
    end;

    local procedure Initialize()
    begin
        // AllObj and AllObjWithCaption are read-only system virtual tables -- nothing to
        // DeleteAll.
    end;
}
