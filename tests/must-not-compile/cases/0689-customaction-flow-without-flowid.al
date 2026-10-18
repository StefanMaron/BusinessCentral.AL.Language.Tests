// @expect AL0674 | The property 'FlowId' is required when property 'CustomActionType' is set to 'Flow'
// A custom action of type Flow needs a FlowId.
table 59689 "MNC U 689"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 59689 "MNC U Custom 689"
{
    PageType = Card;
    SourceTable = "MNC U 689";
    layout { area(Content) { field(Txt; Rec.Txt) { } } }
    actions { area(Processing) { customaction(Flow1) { CustomActionType = Flow; } } }
}
