// @expect AL0133 | Argument 1: cannot convert from 'UserControl Host: "MNC UC Addin 0541"' to 'var ControlAddIn "MNC UC Addin 0541"'
// A page passes its usercontrol (CurrPage.Host) to a var parameter of the ControlAddIn type. The compiler does not convert it. See tests/al-language/pages/lt-f3-pages.
controladdin "MNC UC Addin 0541"
{
    RequestedHeight = 100;
    RequestedWidth = 100;

    procedure SetLocale(Locale: Text);
}

codeunit 59963 "MNC UC Helper 0541"
{
    procedure Take(var Addin: ControlAddIn "MNC UC Addin 0541")
    begin
        Addin.SetLocale('fr-FR');
    end;
}

page 59964 "MNC UC Page 0541"
{
    PageType = Card;

    layout
    {
        area(Content)
        {
            usercontrol(Host; "MNC UC Addin 0541")
            {
            }
        }
    }

    procedure Pass()
    var
        Helper: Codeunit "MNC UC Helper 0541";
    begin
        Helper.Take(CurrPage.Host);
    end;
}
