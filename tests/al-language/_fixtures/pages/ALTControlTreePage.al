// Fixture for record/TestPageControlFieldControlTree.al — the shapes the "Page Control Field"
// (2000000192) virtual table must answer for that "ALT List Page" (60016) does not exercise.
//
// Three properties this page has and the existing fixtures do not:
//   * controls nested THREE group levels deep, so a provider that only walks the top level
//     of the layout cannot answer them;
//   * a control bound to a page VARIABLE rather than to a Rec field — the row still exists
//     on a real tier, and its SourceExpression is the variable's name;
//   * a control bound to a Rec field of type Option, whose OptionString column is the
//     source field's OptionMembers list.
page 60427 "ALT Control Tree Page"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    Caption = 'ALT Control Tree';

    layout
    {
        area(Content)
        {
            group(Level1)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(TreeLocalVar; LocalTreeVar)
                {
                    // Bound to a page variable, not to Rec. A real tier still lists this
                    // control and states the variable name as its SourceExpression.
                    ApplicationArea = All;
                    Caption = 'Local Tree Var';
                }
                group(Level2)
                {
                    field(TreeOption; Rec."Option Field")
                    {
                        ApplicationArea = All;
                    }
                    group(Level3)
                    {
                        field(TreeDeepHidden; Rec."Name Field")
                        {
                            // Depth 3 AND Visible = false: a walk that stops short of this
                            // level cannot answer it, and neither can one that drops
                            // invisible controls.
                            ApplicationArea = All;
                            Visible = false;
                        }
                        field(TreeDeepEditable; Rec."Description Field")
                        {
                            ApplicationArea = All;
                            Editable = false;
                        }
                    }
                }
            }
        }
    }

    var
        LocalTreeVar: Integer;
}
