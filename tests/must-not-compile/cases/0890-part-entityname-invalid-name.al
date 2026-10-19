// @expect AL0484 | The property 'bad name' must be alphanumeric.
// Page part EntityName with a name that is not a valid OData name.
table 50897 "MNC AA T897"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T897"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50897 "MNC AA P897"
{
    PageType = API;
    SourceTable = "MNC AA T897";
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
            part(P; "MNC AA Sub8970") { EntityName = 'bad name'; EntitySetName = 'subs'; }
        }
    }
}
page 58970 "MNC AA Sub8970"
{
    PageType = ListPart;
    SourceTable = "MNC AA T897";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
