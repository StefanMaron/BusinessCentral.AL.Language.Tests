// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: ALT Card Page (60017), ALT List Page (60016), ALT Universal (60000)
//
// Pins the built-in "Page Metadata" system virtual table (2000000138): one row per page
// declared in the application, computed from the page's own metadata rather than stored
// anywhere. Base Application "Page Management" (codeunit 700) falls back to a filtered
// scan of this table (SourceTable + PageType) whenever a table declares no LookupPageId,
// so a provider that answers empty here silently breaks GetDefaultCardPageID one layer up
// — see BusinessCentral.AL.Runner issue #1769. The negative test carries as much weight
// as the positive ones: a provider that answers every Get with true using a fixed/blank
// row would satisfy a naive positive check without ever proving the columns are real.

codeunit 60920 "Test Page Metadata Virt Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageMetadata_Get_CardPage_ReturnsMatchingRow()
    var
        PageMetadata: Record "Page Metadata";
    begin
        Initialize();

        // [WHEN] reading the virtual table for a compiled Card page by its object id
        Assert.IsTrue(PageMetadata.Get(Page::"ALT Card Page"), 'Page Metadata has no row for page ALT Card Page.');

        // [THEN] every column below is computed from the page's own AL declaration, not a
        // default/blank row — this is what distinguishes a real provider from an empty one.
        Assert.AreEqual('ALT Card Page', PageMetadata.Name, 'Unexpected Name for ALT Card Page.');
        Assert.AreEqual(Database::"ALT Universal", PageMetadata.SourceTable, 'Unexpected SourceTable for ALT Card Page.');
        Assert.AreEqual(PageMetadata.PageType::Card, PageMetadata.PageType, 'Unexpected PageType for ALT Card Page.');
    end;

    [Test]
    procedure Record_PageMetadata_Get_ListPage_ReturnsMatchingRow()
    var
        PageMetadata: Record "Page Metadata";
    begin
        Initialize();

        Assert.IsTrue(PageMetadata.Get(Page::"ALT List Page"), 'Page Metadata has no row for page ALT List Page.');

        Assert.AreEqual('ALT List Page', PageMetadata.Name, 'Unexpected Name for ALT List Page.');
        Assert.AreEqual(Database::"ALT Universal", PageMetadata.SourceTable, 'Unexpected SourceTable for ALT List Page.');
        Assert.AreEqual(PageMetadata.PageType::List, PageMetadata.PageType, 'Unexpected PageType for ALT List Page.');
    end;

    [Test]
    procedure Record_PageMetadata_Get_UnknownPageId_ReturnsFalse()
    var
        PageMetadata: Record "Page Metadata";
    begin
        Initialize();

        // Negative control: a provider that answers every Get with true (a fixed/blank row)
        // would pass every positive test above and fail here.
        Assert.IsFalse(PageMetadata.Get(99999999), 'Page Metadata must not have a row for an id no page uses.');
    end;

    local procedure Initialize()
    begin
        // Page Metadata is a read-only system virtual table — nothing to DeleteAll.
    end;
}
