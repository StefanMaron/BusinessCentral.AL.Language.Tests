// Fixture for codeunit 69940 "NRB Blank Part Tests": a host whose part is linked by SubPageLink.
page 69941 "NRB Card"
{
    PageType = Card;
    SourceTable = "NRB Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "NRB Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
