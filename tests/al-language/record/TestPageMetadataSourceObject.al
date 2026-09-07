// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: ALT Source Object Props Page (60994), ALT Source Object Flags Page (60995),
//                ALT Keyed (60006), ALT Status (60009)
//
// Pins the nine columns of the "Page Metadata" system virtual table (2000000138) that are
// computed from a page's <SourceObject> declaration rather than from the page header:
// SourceTableView (15), DelayedInsert (19), ShowFilter (20), MultipleNewLines (21),
// SaveValues (22), AutoSplitKey (23), DataCaptionFields (24), LinksAllowed (26) and
// PopulateAllFields (28).
//
// TestPageMetadataVirtualTable (same folder) already covers Name / SourceTable / PageType.
// It deliberately says nothing about these nine, and that silence is what this file fills.
//
// WHY EACH ASSERTION IS AN EXACT VALUE, NOT A "SOMETHING IS THERE" CHECK
//   Every one of these columns has a type default a provider can answer without consulting
//   the page at all — false for the seven booleans, an empty string for the two text
//   columns. So the fixtures declare each property as the OPPOSITE of its AL default (see
//   the two page files), and every assertion below names the declared value. A provider
//   answering the column's default fails all of them; a provider that has merely wired up
//   the column but reads the wrong page fails them too, since no two fixtures agree.
//
//   The two text columns carry the strongest claims, because their expected values are ones
//   no caller could produce by echoing the AL back:
//     * DataCaptionFields is declared as `"Entry No.", Name` — field NAMES, the only
//       spelling AL accepts — and read back as the field NUMBERS "1,2".
//     * SourceTableView is declared as `where(Status = const(Active))` and read back as
//       BC's own formatted string, naming the field by number and the enum member by
//       ordinal.
//
// A negative control sits at the end: a page declaring none of the nine must report the
// defaults, which is what stops the positive tests from being satisfiable by a provider
// that returns a fixed non-default row.

codeunit 60993 "Test Page Metadata Src Object"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageMetadata_FivePropertyPage_ReportsEachDeclaredValue()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // [GIVEN] a page declaring LinksAllowed/ShowFilter/SaveValues/PopulateAllFields and
        // DataCaptionFields, each as the opposite of its AL default
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT Source Object Props Page"),
            'Page Metadata has no row for page ALT Source Object Props Page.');

        // [THEN] the two columns whose AL default is TRUE report the declared FALSE
        Assert.AreEqual(
            false, PageMetadata.LinksAllowed,
            'LinksAllowed must report the declared false, not the AL default true.');
        Assert.AreEqual(
            false, PageMetadata.ShowFilter,
            'ShowFilter must report the declared false, not the AL default true.');

        // [THEN] the two whose AL default is FALSE report the declared TRUE — the direction
        // a provider answering the column's type default cannot get right
        Assert.AreEqual(
            true, PageMetadata.SaveValues,
            'SaveValues must report the declared true, not the AL default false.');
        Assert.AreEqual(
            true, PageMetadata.PopulateAllFields,
            'PopulateAllFields must report the declared true, not the AL default false.');

        // [THEN] DataCaptionFields is reported as the comma-separated FIELD NUMBERS, even
        // though the page states field NAMES: "Entry No." is field 1 of ALT Keyed and Name
        // is field 2. This is the platform doing the resolution, not the caller.
        Assert.AreEqual(
            '1,2', PageMetadata.DataCaptionFields,
            'DataCaptionFields must report the declared fields as numbers.');
    end;

    [Test]
    procedure Record_PageMetadata_FlagsPage_ReportsThreeDeclaredSourceObjectFlags()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // [GIVEN] a page declaring AutoSplitKey, DelayedInsert and MultipleNewLines, all
        // three of which default to false in AL
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT Source Object Flags Page"),
            'Page Metadata has no row for page ALT Source Object Flags Page.');

        Assert.AreEqual(
            true, PageMetadata.AutoSplitKey,
            'AutoSplitKey must report the declared true, not the AL default false.');
        Assert.AreEqual(
            true, PageMetadata.DelayedInsert,
            'DelayedInsert must report the declared true, not the AL default false.');
        Assert.AreEqual(
            true, PageMetadata.MultipleNewLines,
            'MultipleNewLines must report the declared true, not the AL default false.');
    end;

    [Test]
    procedure Record_PageMetadata_FlagsPage_SourceTableViewReportsFormattedWhereClause()
    var
        PageMetadata: Record "Page Metadata";
        ViewText: Text;
    begin
        // [GIVEN] a page whose SourceTableView declares a where(...) and no sorting(...)
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT Source Object Flags Page"),
            'Page Metadata has no row for page ALT Source Object Flags Page.');
        ViewText := PageMetadata.SourceTableView;

        // [THEN] the column is non-empty, which alone distinguishes a provider that reports
        // the declared view from one answering the empty default
        Assert.AreNotEqual(
            '', ViewText,
            'SourceTableView must not be empty for a page declaring one.');

        // [THEN] and it is BC's own formatted rendering: the field named by NUMBER (Status
        // is field 6 of ALT Keyed) and the enum member by ORDINAL ("ALT Status"::Active is
        // 2) — neither of which appears in the AL the page was written with.
        Assert.AreEqual(
            'WHERE(Field6=CONST(2))', ViewText,
            'SourceTableView must report the declared where clause in BC''s own formatted form.');
    end;

    [Test]
    procedure Record_PageMetadata_SortingOnlyView_ReportsSortingSegment()
    var
        PageMetadata: Record "Page Metadata";
        ViewText: Text;
    begin
        // The existing fixture "ALT Source Table View List" declares all three clauses AL
        // allows — sorting(Amount) order(descending) where(...) — so it pins the segments
        // the where-only page above cannot, and pins that they compose rather than replace
        // one another.
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT Source Table View List"),
            'Page Metadata has no row for page ALT Source Table View List.');
        ViewText := PageMetadata.SourceTableView;

        Assert.AreNotEqual(
            '', ViewText,
            'SourceTableView must not be empty for a page declaring sorting, order and where.');

        // Amount is field 4 of ALT Keyed. A SORTING segment naming it proves the sorting
        // clause reached the column, and does so through the same number-not-name
        // resolution the where clause above goes through.
        Assert.IsTrue(
            ViewText.StartsWith('SORTING(Field4)'),
            'A view declaring sorting(Amount) must open with that key, by field number.');

        // order(descending) — BC renders a descending view as an ORDER segment. Its presence
        // is what separates "the sorting clause was read" from "the whole view was read".
        Assert.IsTrue(
            ViewText.Contains('ORDER('),
            'A view declaring order(descending) must carry an ORDER segment.');

        // and the where(...) survives alongside both of the above, rather than one clause
        // displacing the others.
        Assert.IsTrue(
            ViewText.Contains('WHERE('),
            'A view declaring where(...) must carry a WHERE segment alongside its sorting.');
    end;

    [Test]
    procedure Record_PageMetadata_PageDeclaringNoSourceObjectProperties_ReportsDefaults()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // Negative control, and the reason the positive tests above prove anything: "ALT List
        // Page" declares none of the nine. A provider answering a fixed non-default row —
        // the mirror of the fixed-default failure — passes every assertion above and fails
        // here.
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT List Page"),
            'Page Metadata has no row for page ALT List Page.');

        Assert.AreEqual(
            true, PageMetadata.LinksAllowed,
            'A page declaring no LinksAllowed must report the AL default true.');
        Assert.AreEqual(
            false, PageMetadata.SaveValues,
            'A page declaring no SaveValues must report the AL default false.');
        Assert.AreEqual(
            false, PageMetadata.PopulateAllFields,
            'A page declaring no PopulateAllFields must report the AL default false.');
        Assert.AreEqual(
            false, PageMetadata.AutoSplitKey,
            'A page declaring no AutoSplitKey must report the AL default false.');
        Assert.AreEqual(
            false, PageMetadata.DelayedInsert,
            'A page declaring no DelayedInsert must report the AL default false.');
        Assert.AreEqual(
            false, PageMetadata.MultipleNewLines,
            'A page declaring no MultipleNewLines must report the AL default false.');
        Assert.AreEqual(
            '', PageMetadata.DataCaptionFields,
            'A page declaring no DataCaptionFields must report an empty column.');
        Assert.AreEqual(
            '', PageMetadata.SourceTableView,
            'A page declaring no SourceTableView must report an empty column.');
    end;
}
