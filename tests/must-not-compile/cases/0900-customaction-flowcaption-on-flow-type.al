// @expect AL0167 | The Property 'FlowCaption' can only be used if the property 'CustomActionType' is set with any of the values of: 'FlowTemplate,FlowTemplateGallery'
// Page custom action FlowCaption on a custom action of type Flow.
table 50907 "MNC AA T907"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T907"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50907 "MNC AA P907"
{
    PageType = Card;
    SourceTable = "MNC AA T907";
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
            customaction(C) { CustomActionType = Flow; FlowId = '00001111-aaaa-2222-bbbb-3333cccc4444'; FlowCaption = 'x'; }
        }
    }
}
