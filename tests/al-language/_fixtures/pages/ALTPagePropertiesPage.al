namespace ALT.Test.PageProperties;

// Five of the eleven "Page Metadata" (2000000138) columns Page Metadata reads off a page's
// <Properties> element rather than off its <SourceObject>: RefreshOnActivate (8), a
// namespace declared with `namespace ALT.Test.PageProperties;` (32, "AL Namespace"),
// DataCaptionExpression (7, "DataCaptionExpr."), and InherentPermissions/InherentEntitlements
// (30/31) — the only member either accepts on a page is `X` (Execute); a page cannot declare
// direct read/insert/modify/delete on itself, only the right to be opened.
page 60901 "ALT Page Properties Page"
{
    Caption = 'ALT Page Properties Page';
    PageType = List;
    SourceTable = "ALT Keyed";
    Editable = false;

    RefreshOnActivate = true;
    DataCaptionExpression = 'ALT Page Properties Fixture';
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
