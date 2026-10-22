// @expect AL0186 | Reference 'NoSuchField' in application object 'MNC AA P920' does not exist
// Page repeater IndentationControls names a control that does not exist.
table 50920 "MNC AA T920"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T920"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50920 "MNC AA P920"
{
    PageType = List;
    SourceTable = "MNC AA T920";
    layout
    {
        area(Content)
        {
            repeater(R) { IndentationColumn = Rec.Lvl; IndentationControls = NoSuchField; field(Id2; Rec.Id) { } }
        }
    }
}
