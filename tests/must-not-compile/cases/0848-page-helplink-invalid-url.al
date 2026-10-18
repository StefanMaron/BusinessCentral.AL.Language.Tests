// @expect AL0471 | The format of link 'not a url' is not valid. It should be using the HTTP or HTTPS protocol.
// HelpLink must be a URL.
table 59848 "MNC Z Row 0848"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 52848 "MNC Z Card 0848"
{
    PageType = Card;
    SourceTable = "MNC Z Row 0848";
    HelpLink = 'not a url';
    layout { area(Content) { field(Name; Rec.Name) { } } }
}
