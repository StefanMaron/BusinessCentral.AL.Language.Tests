// @expect AL0155 | A member of type Action with name 'Go' is already defined in Page 'MNC P302' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type Action with name 'Go' is already defined in Page 'MNC P302' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A page has two actions of the same name.
page 50116 "MNC P302"
{
    PageType = Card;
    actions
    {
        area(Processing)
        {
            action(Go) { ApplicationArea = All; }
            action(Go) { ApplicationArea = All; }
        }
    }
}
