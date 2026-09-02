page 60016 "ALT List Page"
{
    PageType = List;
    SourceTable = "ALT Universal";
    Caption = 'ALT Universal List';
    Editable = true;

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
                field("Integer Field"; Rec."Integer Field")
                {
                    ApplicationArea = All;
                }
                field("Text Field"; Rec."Text Field")
                {
                    ApplicationArea = All;
                }
                field("Decimal Field"; Rec."Decimal Field")
                {
                    ApplicationArea = All;
                }
                field("Date Field"; Rec."Date Field")
                {
                    ApplicationArea = All;
                }
                field("Status Field"; Rec."Status Field")
                {
                    ApplicationArea = All;
                }
                field("Option Field"; Rec."Option Field")
                {
                    // The plain Option primitive, next to the Enum-typed "Status Field" above:
                    // TestPageExtended's AssertEquals tests need BOTH, because an Option control
                    // has no per-value Caption of its own while an Enum's values do.
                    ApplicationArea = All;
                }
                field("Name Field"; Rec."Name Field")
                {
                    // Deliberately hidden: TestPageMetadataVirtualTable / TestPageControlFieldVirtualTable
                    // (record/) prove the Page Control Field virtual table's Visible column round-trips a
                    // hidden control's declared Visible = false, not just the visible default.
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestAction)
            {
                ApplicationArea = All;
                Caption = 'Test Action';
                trigger OnAction()
                begin
                    Message('Action triggered for entry %1', Rec."Entry No.");
                end;
            }
        }
    }
}
