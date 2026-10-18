// @expect AL0186 | Reference 'NoSuchAction' in application object 'MNC AA P901' does not exist
// Page part FileUploadAction names an action that does not exist.
table 50901 "MNC AA T901"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T901"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50901 "MNC AA P901"
{
    PageType = Card;
    SourceTable = "MNC AA T901";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(P; "MNC AA Sub9010") { FileUploadAction = NoSuchAction; }
        }
    }
}
page 59010 "MNC AA Sub9010"
{
    PageType = ListPart;
    SourceTable = "MNC AA T901";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
