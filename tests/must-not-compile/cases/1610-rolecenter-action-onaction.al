// @expect AL0378 | A page of type Role Center cannot have triggers. Remove all trigger implementations from this page.
// Corpus issue #667 item 29: an OnAction trigger on an action of a Role Center page (the page itself has no trigger).
// An action with RunObject on a Role Center compiles (see tests/al-language/misc/lt-cb-odd-leads/CbFixtures.al, page "LT CB Role Center").
page 59612 "MNC RC 1610"
{
    PageType = RoleCenter;

    actions
    {
        area(Processing)
        {
            action(RcAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}
