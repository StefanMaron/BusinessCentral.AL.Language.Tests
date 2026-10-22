// @expect AL0155 | A member of type Action with name 'Post' is already defined in Page 'MNC CL Dup 1690'
// @expect AL0155 | A member of type Group with name 'Post' is already defined in Page 'MNC CL Dup 1690'
// A page has an action group and an action with the same name: the page does not compile, so no subscriber can name an ambiguous action
// (corpus issue 669, item 26; microsoft/AL issue 1907 crashed the compiler with "Sequence contains multiple elements" on a C/SIDE page).
page 51690 "MNC CL Dup 1690"
{
    PageType = Card;
    SourceTable = Customer;

    actions
    {
        area(Processing)
        {
            group(Post)
            {
                action(Post)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
    }
}
