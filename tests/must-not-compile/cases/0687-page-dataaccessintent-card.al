// @expect AL0223 | The Property 'DataAccessIntent' can only be used if the property 'PageType' is set to 'API'
// @expect AL0223 | The Property 'DataAccessIntent' can only be used if the property 'Editable' is set to 'false'
// DataAccessIntent is allowed on an API page only, and then only with Editable = false.
table 59687 "MNC U 687"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 59687 "MNC U Intent 687"
{
    PageType = Card;
    SourceTable = "MNC U 687";
    DataAccessIntent = ReadOnly;
    layout { area(Content) { field(Txt; Rec.Txt) { } } }
}
