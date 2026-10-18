// @expect AL0169 | The option value 'Parent' is not valid. Check the enum definition for valid values.
// Page part UpdatePropagation with a value that is not SubPart or Both.
table 50900 "MNC AA T900"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T900"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50900 "MNC AA P900"
{
    PageType = Card;
    SourceTable = "MNC AA T900";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(P; "MNC AA Sub9000") { UpdatePropagation = Parent; }
        }
    }
}
page 59000 "MNC AA Sub9000"
{
    PageType = ListPart;
    SourceTable = "MNC AA T900";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
