page 60020 "ALT Triggered Card Page"
{
    PageType = Card;
    SourceTable = "ALT Triggered";
    Caption = 'ALT Triggered Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                }
                field("Value"; Rec."Value")
                {
                    ApplicationArea = All;
                }
                field("Watched Field"; Rec."Watched Field")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
