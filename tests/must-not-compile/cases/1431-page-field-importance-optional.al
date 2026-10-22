// @expect AL0666 | 'Optional' is not available in runtime version '
// Importance = Optional on a page field (microsoft/AL issue 4648): refused for the app runtime of every BC major. The full text names the
// app runtime ('16.1', '17.1', '18.0') and then "The supported runtime versions are: '1.0' until, but not including '3.0'.", so the
// recorded text stops before the version.
table 51431 "MNC BP T1431"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51431 "MNC BP P1431"
{
    PageType = Card;
    SourceTable = "MNC BP T1431";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { Importance = Optional; }
        }
    }
}
