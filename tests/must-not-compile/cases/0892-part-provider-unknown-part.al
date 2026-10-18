// @expect AL0186 | Reference 'NoSuchPart' in application object 'MNC AA P899' does not exist
// Page part Provider names a part that is not on the page.
table 50899 "MNC AA T899"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T899"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50899 "MNC AA P899"
{
    PageType = Card;
    SourceTable = "MNC AA T899";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(P; "MNC AA Sub8990") { Provider = NoSuchPart; }
        }
    }
}
page 58990 "MNC AA Sub8990"
{
    PageType = ListPart;
    SourceTable = "MNC AA T899";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
