// @expect AL0155 | A member of type Action with name 'Description' is already defined in Page 'MNC BP P1433' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type Field with name 'Description' is already defined in Page 'MNC BP P1433' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A page field and a page action with the same name (microsoft/AL issues 766 and 411): both declarations get AL0155. Two actions of one
// name: case 0302.
table 51433 "MNC BP T1433"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Description; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51433 "MNC BP P1433"
{
    PageType = Card;
    SourceTable = "MNC BP T1433";

    layout
    {
        area(Content)
        {
            field(Description; Rec.Description) { }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Description)
            {
                trigger OnAction()
                begin
                end;
            }
        }
    }
}
