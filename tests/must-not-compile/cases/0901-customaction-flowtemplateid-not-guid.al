// @expect AL0734 | The value 'abc' of the property 'FlowTemplateId' is not a valid GUID.
// Page custom action FlowTemplateId that is not a GUID.
table 50908 "MNC AA T908"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T908"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50908 "MNC AA P908"
{
    PageType = Card;
    SourceTable = "MNC AA T908";
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
            customaction(C) { CustomActionType = FlowTemplate; FlowTemplateId = 'abc'; }
        }
    }
}
