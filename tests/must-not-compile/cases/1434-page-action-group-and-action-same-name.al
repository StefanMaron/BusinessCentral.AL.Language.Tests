// @expect AL0155 | A member of type Action with name 'Resources' is already defined in Page 'MNC BP P1434' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type Group with name 'Resources' is already defined in Page 'MNC BP P1434' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// An action group and an action inside it with the same name (microsoft/AL issues 1726 and 1695): both declarations get AL0155.
page 51434 "MNC BP P1434"
{
    PageType = Card;

    actions
    {
        area(Processing)
        {
            group(Resources)
            {
                action(Resources)
                {
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
    }
}
