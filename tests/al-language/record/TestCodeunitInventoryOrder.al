// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: ALT Codeunit Meta Probe (60963), SIS Cache (60608),
//                Test AllObj Virtual Table (60802)
// BC versions: 27.0+
//
// Pins the ROW ORDER of the two codeunit inventories -- "CodeUnit Metadata" (2000000137)
// and "AllObjWithCaption" (2000000058) -- when they are read with a plain FindSet() and no
// SetCurrentKey. TestCodeunitMetadataVirtualTable.al pins what each COLUMN of CodeUnit
// Metadata reports; nothing pinned the order the rows arrive in, and that order is a
// separate, observable contract.
//
// It is a contract BC itself depends on. Every entry point the shipped Test Runner app
// offers for populating a test suite -- Test Suite Mgt.'s SelectTestMethods,
// SelectTestMethodsByRange and SelectTestMethodsByExtension -- funnels into GetTestMethods,
// which walks one of these two inventories with a bare FindSet()/Next() and no
// SetCurrentKey, handing each row a monotonically increasing "Line No.". So whatever order
// these tables answer in IS the order such a suite lists its test codeunits in.
//
// The discriminating detail is that the ID filter is written in a deliberately SCRAMBLED
// token order, and written two different ways for the same three codeunits. An
// implementation that replayed the filter's tokens, or that ordered by Name, or that
// answered a fixed list, fails at least one test below. Initialize() has nothing to reset:
// both tables are read-only system virtual tables.

codeunit 60964 "Test Codeunit Inventory Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_CodeunitMetadata_FindSetWithoutSetCurrentKey_ReturnsAscendingId()
    // CLAIM: a filtered FindSet() over CodeUnit Metadata with no SetCurrentKey returns rows
    // in ascending ID -- not in the order the filter named them.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        // [GIVEN] a filter naming three codeunits in an order that is NOT ascending by id:
        //         Test AllObj Virtual Table (60802), ALT Codeunit Meta Probe (60963),
        //         SIS Cache (60608).
        SetScrambledFilterA(CodeunitMetadata);

        // [THEN] the three rows arrive lowest id first, whatever the filter said.
        Assert.AreEqual(
            AscendingIdSequence(), IdSequence(CodeunitMetadata),
            'A filtered FindSet() over CodeUnit Metadata must return rows in ascending ID.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_FilterTokenOrderDoesNotDecideRowOrder()
    // CLAIM: two different spellings of the same ID filter produce the same row order.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
        FromSpellingA: Text;
        FromSpellingB: Text;
    begin
        Initialize();

        SetScrambledFilterA(CodeunitMetadata);
        FromSpellingA := IdSequence(CodeunitMetadata);

        // A different token order over the identical set of three codeunits.
        SetScrambledFilterB(CodeunitMetadata);
        FromSpellingB := IdSequence(CodeunitMetadata);

        Assert.AreEqual(
            FromSpellingA, FromSpellingB,
            'The row order must not depend on the order the ID filter names its tokens.');
        Assert.AreEqual(
            AscendingIdSequence(), FromSpellingB,
            'Both spellings of the filter must yield ascending ID.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_AscendingFalse_ReturnsDescendingId()
    // CLAIM: the ascending answer above comes from the key direction, so reversing the key
    // direction reverses the rows. A provider replaying a fixed ascending list fails here.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        SetScrambledFilterA(CodeunitMetadata);
        CodeunitMetadata.SetCurrentKey(ID);
        CodeunitMetadata.Ascending(false);

        Assert.AreEqual(
            DescendingIdSequence(), IdSequence(CodeunitMetadata),
            'Ascending(false) on the ID key must return the same three rows highest id first.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_RowOrderIsByIdNotByName()
    // CLAIM: the rows are ordered by ID, not alphabetically by Name. The three codeunits are
    // picked so the two orders disagree: 'ALT Codeunit Meta Probe' sorts FIRST by name and
    // LAST by id.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
        Names: Text;
    begin
        Initialize();

        SetScrambledFilterA(CodeunitMetadata);
        Assert.IsTrue(CodeunitMetadata.FindSet(), 'FindSet must succeed for three existing codeunits.');
        repeat
            if Names <> '' then
                Names += ',';
            Names += CodeunitMetadata.Name;
        until CodeunitMetadata.Next() = 0;

        Assert.AreEqual(
            'SIS Cache,Test AllObj Virtual Table,ALT Codeunit Meta Probe', Names,
            'The rows must arrive in ascending ID order, which for these three is not alphabetical order.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_FindFirstAndFindLast_AreLowestAndHighestId()
    // CLAIM: both ends of the filtered set are decided by the ID key.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        SetScrambledFilterA(CodeunitMetadata);
        Assert.IsTrue(CodeunitMetadata.FindFirst(), 'FindFirst must succeed for three existing codeunits.');
        Assert.AreEqual(
            Codeunit::"SIS Cache", CodeunitMetadata.ID,
            'FindFirst must return the lowest id in the filter, not the first id the filter names.');

        SetScrambledFilterA(CodeunitMetadata);
        Assert.IsTrue(CodeunitMetadata.FindLast(), 'FindLast must succeed for three existing codeunits.');
        Assert.AreEqual(
            Codeunit::"ALT Codeunit Meta Probe", CodeunitMetadata.ID,
            'FindLast must return the highest id in the filter.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_TestCodeunitsInThisAppsRange_AreStrictlyAscending()
    // CLAIM: the whole-app walk -- the one BC's Test Suite Mgt. performs, SubType = Test over
    // an id range -- is strictly ascending with no repeats.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
        PreviousId: Integer;
        Seen: Integer;
    begin
        Initialize();

        CodeunitMetadata.SetRange(SubType, CodeunitMetadata.SubType::Test);
        CodeunitMetadata.SetRange(ID, 60000, 60999);
        Assert.IsTrue(CodeunitMetadata.FindSet(), 'This app declares test codeunits in 60000..60999.');

        PreviousId := 0;
        repeat
            Seen += 1;
            Assert.IsTrue(
                CodeunitMetadata.ID > PreviousId,
                StrSubstNo(
                    'CodeUnit Metadata returned id %1 after id %2 — the walk must be strictly ascending.',
                    CodeunitMetadata.ID, PreviousId));
            PreviousId := CodeunitMetadata.ID;
        until CodeunitMetadata.Next() = 0;

        // Guards the assertion above against becoming vacuous on a one-row or empty set.
        Assert.IsTrue(
            Seen >= 50,
            StrSubstNo('Expected at least 50 test codeunits in 60000..60999, walked %1.', Seen));
    end;

    [Test]
    procedure Record_AllObjWithCaption_CodeunitRows_FindSetReturnsAscendingObjectId()
    // CLAIM: the same order holds for the other inventory, AllObjWithCaption, whose key is
    // ("Object Type", "Object ID"). BC's pre-CLEAN27 GetTestMethods overload walks this one.
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Ids: Text;
    begin
        Initialize();

        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetFilter(
            "Object ID", '%1|%2|%3',
            Codeunit::"Test AllObj Virtual Table", Codeunit::"ALT Codeunit Meta Probe", Codeunit::"SIS Cache");

        Assert.IsTrue(AllObjWithCaption.FindSet(), 'FindSet must succeed for three existing codeunits.');
        repeat
            if Ids <> '' then
                Ids += ',';
            Ids += Format(AllObjWithCaption."Object ID");
        until AllObjWithCaption.Next() = 0;

        Assert.AreEqual(
            AscendingIdSequence(), Ids,
            'AllObjWithCaption must return the codeunit rows in ascending Object ID.');
    end;

    [Test]
    procedure Record_CodeunitMetadata_FilterNamingNoCodeunit_ReturnsNoRows()
    // Negative control: the walks above must be selecting real rows, not answering a fixed
    // list regardless of the filter.
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Initialize();

        CodeunitMetadata.SetFilter(ID, '%1|%2', 99999998, 99999999);

        Assert.IsFalse(CodeunitMetadata.FindSet(), 'A filter naming no codeunit must select no rows.');
        Assert.AreEqual(0, CodeunitMetadata.Count(), 'A filter naming no codeunit must count zero.');
    end;

    local procedure SetScrambledFilterA(var CodeunitMetadata: Record "CodeUnit Metadata")
    begin
        CodeunitMetadata.Reset();
        // Token order 60802, 60963, 60608 — neither ascending id nor alphabetical by name.
        CodeunitMetadata.SetFilter(
            ID, '%1|%2|%3',
            Codeunit::"Test AllObj Virtual Table", Codeunit::"ALT Codeunit Meta Probe", Codeunit::"SIS Cache");
    end;

    local procedure SetScrambledFilterB(var CodeunitMetadata: Record "CodeUnit Metadata")
    begin
        CodeunitMetadata.Reset();
        // Same three codeunits, token order 60963, 60608, 60802.
        CodeunitMetadata.SetFilter(
            ID, '%1|%2|%3',
            Codeunit::"ALT Codeunit Meta Probe", Codeunit::"SIS Cache", Codeunit::"Test AllObj Virtual Table");
    end;

    local procedure IdSequence(var CodeunitMetadata: Record "CodeUnit Metadata"): Text
    var
        Ids: Text;
    begin
        Assert.IsTrue(CodeunitMetadata.FindSet(), 'FindSet must succeed for three existing codeunits.');
        repeat
            if Ids <> '' then
                Ids += ',';
            Ids += Format(CodeunitMetadata.ID);
        until CodeunitMetadata.Next() = 0;
        exit(Ids);
    end;

    local procedure AscendingIdSequence(): Text
    begin
        exit(
            StrSubstNo(
                '%1,%2,%3',
                Codeunit::"SIS Cache", Codeunit::"Test AllObj Virtual Table", Codeunit::"ALT Codeunit Meta Probe"));
    end;

    local procedure DescendingIdSequence(): Text
    begin
        exit(
            StrSubstNo(
                '%1,%2,%3',
                Codeunit::"ALT Codeunit Meta Probe", Codeunit::"Test AllObj Virtual Table", Codeunit::"SIS Cache"));
    end;

    local procedure Initialize()
    begin
        // Both inventories are read-only system virtual tables — nothing to reset. What DOES
        // need asserting is that the three codeunits this file leans on still stand in the
        // relative order the tests assume; a renumbering would otherwise make every ordering
        // assertion above quietly stop discriminating.
        Assert.IsTrue(
            Codeunit::"SIS Cache" < Codeunit::"Test AllObj Virtual Table",
            'Fixture assumption broken: SIS Cache must have a lower object id than Test AllObj Virtual Table.');
        Assert.IsTrue(
            Codeunit::"Test AllObj Virtual Table" < Codeunit::"ALT Codeunit Meta Probe",
            'Fixture assumption broken: Test AllObj Virtual Table must have a lower object id than ALT Codeunit Meta Probe.');
    end;
}
