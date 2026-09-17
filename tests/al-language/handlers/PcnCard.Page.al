// Fixture for "PCN Tests" (60535). A card over "PCN Header" (60533) hosting "PCN Lines Part"
// (60534). No triggers and no declared actions: the suite measures what the platform itself
// does with a pending part row when the built-in Cancel closes the card, so anything this page
// did of its own would be in the way.
page 60533 "PCN Card"
{
    PageType = Card;
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
