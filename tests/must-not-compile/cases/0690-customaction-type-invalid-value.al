// @expect AL0169 | The option value 'Mystery' is not valid. Check the enum definition for valid values.
// CustomActionType takes a known value only.
table 59690 "MNC U 690"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 59690 "MNC U Custom 690"
{
    PageType = Card;
    SourceTable = "MNC U 690";
    layout { area(Content) { field(Txt; Rec.Txt) { } } }
    actions { area(Processing) { customaction(Custom1) { CustomActionType = Mystery; } } }
}
