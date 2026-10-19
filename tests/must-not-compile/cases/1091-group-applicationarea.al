// @expect AL0124 | The property 'ApplicationArea' cannot be used in this context.
// A page group sets ApplicationArea: the property is not available on a group, so a group cannot be removed by application areas.
table 51091 "MNC AN T1091"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
}

page 51091 "MNC AN P1091"
{
    PageType = Card;
    SourceTable = "MNC AN T1091";

    layout
    {
        area(Content)
        {
            group(SuiteGroup)
            {
                ApplicationArea = Suite;

                field(Name; Rec.Name) { ApplicationArea = Basic; }
            }
        }
    }
}
