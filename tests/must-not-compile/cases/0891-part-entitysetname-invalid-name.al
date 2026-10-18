// @expect AL0484 | The property '1 bad' must be alphanumeric.
// Page part EntitySetName with a name that is not a valid OData name.
table 50898 "MNC AA T898"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T898"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50898 "MNC AA P898"
{
    PageType = API;
    SourceTable = "MNC AA T898";
    APIPublisher = 'aa';
    APIGroup = 'aa';
    APIVersion = 'v1.0';
    EntityName = 'aa';
    EntitySetName = 'aas';
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(id; Rec.SystemId) { }
            }
            part(P; "MNC AA Sub8980") { EntityName = 'sub'; EntitySetName = '1 bad'; }
        }
    }
}
page 58980 "MNC AA Sub8980"
{
    PageType = ListPart;
    SourceTable = "MNC AA T898";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
