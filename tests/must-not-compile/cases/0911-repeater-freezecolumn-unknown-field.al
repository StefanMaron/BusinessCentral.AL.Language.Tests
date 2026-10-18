// @expect AL0186 | Reference 'NoSuchField' in application object 'MNC AA P918' does not exist
// Page repeater FreezeColumn names a control that does not exist.
table 50918 "MNC AA T918"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T918"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50918 "MNC AA P918"
{
    PageType = List;
    SourceTable = "MNC AA T918";
    layout
    {
        area(Content)
        {
            repeater(R) { FreezeColumn = NoSuchField; field(Id2; Rec.Id) { } }
        }
    }
}
