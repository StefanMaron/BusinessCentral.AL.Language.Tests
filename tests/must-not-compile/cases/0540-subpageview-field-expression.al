// @expect AL0489 | The property expression is not valid. A CONST or FILTER expression is expected.
// A part's SubPageView names its field with field(...) instead of const(...) or filter(...). Only SubPageLink takes field(...). See tests/al-language/pages/lt-f3-pages.
table 59960 "MNC SPV Table 0540"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 59961 "MNC SPV Part 0540"
{
    PageType = ListPart;
    SourceTable = "MNC SPV Table 0540";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { }
            }
        }
    }
}

page 59962 "MNC SPV Host 0540"
{
    PageType = Card;
    SourceTable = "MNC SPV Table 0540";

    layout
    {
        area(Content)
        {
            part(Lines; "MNC SPV Part 0540")
            {
                SubPageView = where("Code" = field("Code"));
            }
        }
    }
}
