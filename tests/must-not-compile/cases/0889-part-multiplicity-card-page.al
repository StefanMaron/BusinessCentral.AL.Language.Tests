// @expect AL0223 | The Property 'Multiplicity' can only be used if the property 'PageType' is set to 'API'
// Page part Multiplicity on a Card page.
table 50896 "MNC AA T896"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T896"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50896 "MNC AA P896"
{
    PageType = Card;
    SourceTable = "MNC AA T896";
    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            part(P; "MNC AA Sub8960") { Multiplicity = Many; }
        }
    }
}
page 58960 "MNC AA Sub8960"
{
    PageType = ListPart;
    SourceTable = "MNC AA T896";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
