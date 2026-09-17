// Fixture for "PCN Tests" (60535). The same header and part as "PCN Card" (60533), on a
// StandardDialog instead of a Card. Two page types, because whether a page has a built-in
// Cancel at all is a property of the chrome its builder puts on the form and the types do not
// agree ("TBA Tests" (60338) measures four that differ): a StandardDialog is already known to
// offer one -- "Test Page Modal" (60703) is one and codeunit 60702 invokes its Cancel -- so if
// the Card arms turn out to have no Cancel to invoke, these arms still answer the question this
// suite exists for.
page 60535 "PCN Dialog"
{
    PageType = StandardDialog;
    SourceTable = "PCN Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "PCN Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code");
            }
        }
    }
}
