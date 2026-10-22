// @expect AL0169 | The option value 'Row' is not valid
// Page custom action Scope with a value that is not Page or Repeater.
table 50906 "MNC AA T906"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T906"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50906 "MNC AA P906"
{
    PageType = Card;
    SourceTable = "MNC AA T906";
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
            customaction(C) { CustomActionType = Flow; FlowId = '00001111-aaaa-2222-bbbb-3333cccc4444'; Scope = Row; }
        }
    }
}
