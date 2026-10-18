// @expect AL0428 | Cannot specify EntitySetCaptionML and EntitySetCaption property at the same time. Use only the EntitySetCaption property.
// @expect AL0428 | Cannot specify EntitySetCaptionML and EntitySetCaption property at the same time. Use only the EntitySetCaption property.
// EntitySetCaption and EntitySetCaptionML cannot both be set on an API page.
table 59843 "MNC Z Row 0843"
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
page 52843 "MNC Z Api 0843"
{
    PageType = API;
    SourceTable = "MNC Z Row 0843";
    APIPublisher = 'ltz'; APIGroup = 'ltz'; APIVersion = 'v1.0';
    EntityName = 'ltzRow'; EntitySetName = 'ltzRows';
    EntitySetCaption = 'Rows';
    EntitySetCaptionML = ENU = 'Rows', DEU = 'Zeilen';
    ODataKeyFields = Id; DelayedInsert = true;
    layout { area(Content) { repeater(R) { field(id; Rec.Id) { } } } }
}
