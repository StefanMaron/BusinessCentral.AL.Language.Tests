// @expect AL0204 | Field type Text is not convertible to field type Option.
// @expect AL0204 | Field type Text is not convertible to field type Sales Document Type.
// RunPageLink from a Text field of the target page's table to an Option field and to an Enum field of the source table (microsoft/AL
// issue 2445): both are refused.
table 51438 "MNC BP T1438"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Primary Key Field 1 Value"; Text[50]) { }
        field(3; Kind; Option) { OptionMembers = A,B; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51438 "MNC BP P1438"
{
    PageType = List;
    SourceTable = "MNC BP T1438";

    layout
    {
        area(Content)
        {
            repeater(G)
            {
                field(Id; Rec.Id) { }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ToOption)
            {
                RunObject = page "MNC BP P1438";
                RunPageLink = "Primary Key Field 1 Value" = field(Kind);
            }
        }
    }
}
page 51439 "MNC BP P1439"
{
    PageType = Card;
    SourceTable = "Sales Header";

    actions
    {
        area(Processing)
        {
            action(ToEnum)
            {
                RunObject = page "MNC BP P1438";
                RunPageLink = "Primary Key Field 1 Value" = field("Document Type");
            }
        }
    }
}
