// @expect AL0186 | Reference 'NoSuchAction' in application object 'MNC AA P925' does not exist
// Page repeater FileUploadAction names an action that does not exist.
table 50925 "MNC AA T925"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T925"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50925 "MNC AA P925"
{
    PageType = List;
    SourceTable = "MNC AA T925";
    layout
    {
        area(Content)
        {
            repeater(R) { FileUploadAction = NoSuchAction; field(Id2; Rec.Id) { } }
        }
    }
}
