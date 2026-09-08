// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-page-refreshonactivate-property
// Scope: in-scope
// Fixtures used: ALT Page Properties Page (60901), ALT Page Properties Api Page (60902),
//                ALT List Page (60016)
//
// Pins the eleven columns of the "Page Metadata" system virtual table (2000000138) that are
// computed from a page's <Properties> element rather than from the page header or its
// <SourceObject>: RefreshOnActivate (8), APIPublisher (9), APIGroup (10), APIVersion (11),
// EntitySetName (12), EntityName (13), ChangeTrackingAllowed (27), InherentPermissions (30),
// InherentEntitlements (31), "AL Namespace" (32) and "DataCaptionExpr." (7).
//
// TestPageMetadataVirtualTable (same folder) already covers Name/SourceTable/PageType, and
// TestPageMetadataSourceObject covers the nine <SourceObject> columns. Both deliberately say
// nothing about these eleven, and that silence is what this file fills.
//
// WHY EACH ASSERTION IS AN EXACT VALUE, NOT A "SOMETHING IS THERE" CHECK
//   Every one of these columns has a type default a provider can answer without consulting
//   the page at all — false for the two booleans, an empty string for most of the rest. So
//   the fixtures declare each property as the OPPOSITE of its default, and every assertion
//   below names the declared value. A provider answering the column's default fails all of
//   them. APIVersion is the one exception: BC's own MetaPageProperties.APIVersion getter
//   returns "beta", not "", for a page declaring none — pinned in the negative-control test
//   below rather than assumed.
//
//   "DataCaptionExpr." carries the strongest claim, because its expected value is not what a
//   caller reading the AL source would guess: `DataCaptionExpression = 'ALT Page Properties
//   Fixture';` compiles to the FIXED placeholder text "DataCaptionExprCode" on every page that
//   declares the property, whatever text or expression it names — verified against the AL
//   compiler with two different literal expressions producing the identical column value. The
//   column is therefore proof that BC's own compiled document was read, not an echo of the AL.
//
//   InherentPermissions/InherentEntitlements carry the second-strongest claim: a PAGE can only
//   ever declare `X` (Execute) for either — `rimd` is rejected by the compiler with "Invalid
//   permission kind. Expected: 'X'" — so both columns are expected to read the single
//   character "X", not a multi-letter mask the way the same columns behave on a table.
//
// A negative control sits at the end: a page declaring none of the eleven must report the
// defaults, which is what stops the positive tests above from being satisfiable by a provider
// that returns a fixed non-default row.

codeunit 60904 "Test Page Metadata Properties"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageMetadata_PropertiesPage_ReportsDeclaredPropertiesColumns()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // [GIVEN] a page declaring RefreshOnActivate, a namespace, DataCaptionExpression and
        // InherentPermissions/InherentEntitlements, each the opposite of its AL default
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT Page Properties Page"),
            'Page Metadata has no row for page ALT Page Properties Page.');

        // [THEN] RefreshOnActivate reports the declared true, not the AL default false
        Assert.AreEqual(
            true, PageMetadata.RefreshOnActivate,
            'RefreshOnActivate must report the declared true, not the AL default false.');

        // [THEN] "AL Namespace" reports the file's `namespace` directive, not the empty
        // default a page declaring none carries
        Assert.AreEqual(
            'ALT.Test.PageProperties', PageMetadata."AL Namespace",
            'AL Namespace must report the file''s namespace directive.');

        // [THEN] "DataCaptionExpr." reports BC's own fixed placeholder for a compiled
        // DataCaptionExpression, not the empty default and not the AL source text
        Assert.AreEqual(
            'DataCaptionExprCode', PageMetadata."DataCaptionExpr.",
            'DataCaptionExpr. must report BC''s own compiled placeholder for the declared expression.');

        // [THEN] a page can only declare Execute for either permission column
        Assert.AreEqual(
            'X', PageMetadata.InherentPermissions,
            'InherentPermissions must report the declared X, not the empty default.');
        Assert.AreEqual(
            'X', PageMetadata.InherentEntitlements,
            'InherentEntitlements must report the declared X, not the empty default.');
    end;

    [Test]
    procedure Record_PageMetadata_ApiPage_ReportsDeclaredApiAndEntityColumns()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // [GIVEN] an API page declaring APIPublisher/APIGroup/APIVersion/EntityName/
        // EntitySetName/ChangeTrackingAllowed
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT Page Properties Api Page"),
            'Page Metadata has no row for page ALT Page Properties Api Page.');

        Assert.AreEqual(
            'altpublisher', PageMetadata.APIPublisher,
            'APIPublisher must report the declared value, not the empty default.');
        Assert.AreEqual(
            'altgroup', PageMetadata.APIGroup,
            'APIGroup must report the declared value, not the empty default.');
        Assert.AreEqual(
            'v1.0', PageMetadata.APIVersion,
            'APIVersion must report the declared value, not the empty default.');
        Assert.AreEqual(
            'altPagePropertiesEntity', PageMetadata.EntityName,
            'EntityName must report the declared value, not the empty default.');
        Assert.AreEqual(
            'altPagePropertiesEntities', PageMetadata.EntitySetName,
            'EntitySetName must report the declared value, not the empty default.');
        Assert.AreEqual(
            true, PageMetadata.ChangeTrackingAllowed,
            'ChangeTrackingAllowed must report the declared true, not the AL default false.');
    end;

    [Test]
    procedure Record_PageMetadata_PageDeclaringNoPropertiesColumns_ReportsDefaults()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // Negative control, and the reason the positive tests above prove anything: "ALT List
        // Page" declares none of the eleven and carries no `namespace` directive. A provider
        // answering a fixed non-default row — the mirror of the fixed-default failure — passes
        // every assertion above and fails here.
        Assert.IsTrue(
            PageMetadata.Get(Page::"ALT List Page"),
            'Page Metadata has no row for page ALT List Page.');

        Assert.AreEqual(
            false, PageMetadata.RefreshOnActivate,
            'A page declaring no RefreshOnActivate must report the AL default false.');
        Assert.AreEqual(
            '', PageMetadata."AL Namespace",
            'A page declaring no namespace directive must report an empty AL Namespace.');
        Assert.AreEqual(
            '', PageMetadata."DataCaptionExpr.",
            'A page declaring no DataCaptionExpression must report an empty DataCaptionExpr.');
        Assert.AreEqual(
            '', PageMetadata.InherentPermissions,
            'A page declaring no InherentPermissions must report an empty column.');
        Assert.AreEqual(
            '', PageMetadata.InherentEntitlements,
            'A page declaring no InherentEntitlements must report an empty column.');
        Assert.AreEqual(
            '', PageMetadata.APIPublisher,
            'A page declaring no APIPublisher must report an empty column.');
        Assert.AreEqual(
            '', PageMetadata.APIGroup,
            'A page declaring no APIGroup must report an empty column.');
        // BC's own MetaPageProperties.APIVersion getter returns the literal "beta" when
        // the field is unset ([DefaultValue("beta")] on the real type, decompiled), not
        // an empty string — the one column of the eleven whose "declares none" default
        // is not its type's ordinary default. A page not targeting a specific API version
        // is implicitly on the beta surface, which is what this pins.
        Assert.AreEqual(
            'beta', PageMetadata.APIVersion,
            'A page declaring no APIVersion must report BC''s own "beta" default, not an empty column.');
        Assert.AreEqual(
            '', PageMetadata.EntityName,
            'A page declaring no EntityName must report an empty column.');
        Assert.AreEqual(
            '', PageMetadata.EntitySetName,
            'A page declaring no EntitySetName must report an empty column.');
        Assert.AreEqual(
            false, PageMetadata.ChangeTrackingAllowed,
            'A page declaring no ChangeTrackingAllowed must report the AL default false.');
    end;
}
