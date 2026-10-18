// @expect AL0132 | 'UserControl Ctl: "MNC Addin 0991"' does not contain a definition for 'Missing'
// A page calls a procedure that the control add-in does not declare. Runtime test for the valid call: tests/al-language/lt-ac/ACControlAddIn.al.
controladdin "MNC Addin 0991"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Say(Message: Text);
}

page 59115 "MNC Addin Page 0991"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(Ctl; "MNC Addin 0991")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Ctl.Missing();
    end;
}
