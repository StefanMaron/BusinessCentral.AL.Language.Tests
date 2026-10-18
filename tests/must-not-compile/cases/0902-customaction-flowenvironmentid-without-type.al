// @expect AL0168 | The Property 'FlowEnvironmentId' can only be used if the property 'FlowId' is set
// Page custom action FlowEnvironmentId on a custom action without CustomActionType.
table 50909 "MNC AA T909"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T909"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50909 "MNC AA P909"
{
    PageType = Card;
    SourceTable = "MNC AA T909";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
    actions
    {
        area(Processing)
        {
            customaction(C) { FlowEnvironmentId = 'Default-44445555-eeee-6666-ffff-7777aaaa8888'; }
        }
    }
}
