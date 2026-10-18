// @expect AL0428 | Cannot specify EntityCaptionML and EntityCaption property at the same time. Use only the EntityCaption property.
// @expect AL0428 | Cannot specify EntityCaptionML and EntityCaption property at the same time. Use only the EntityCaption property.
// EntityCaption and EntityCaptionML cannot both be set on an API page.
table 59842 "MNC Z Row 0842"
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
page 52842 "MNC Z Api 0842"
{
    PageType = API;
    SourceTable = "MNC Z Row 0842";
    APIPublisher = 'ltz'; APIGroup = 'ltz'; APIVersion = 'v1.0';
    EntityName = 'ltzRow'; EntitySetName = 'ltzRows';
    EntityCaption = 'Row';
    EntityCaptionML = ENU = 'Row', DEU = 'Zeile';
    ODataKeyFields = Id; DelayedInsert = true;
    layout { area(Content) { repeater(R) { field(id; Rec.Id) { } } } }
}
