// @expect AL0169 | The option value 'Several' is not valid. Check the enum definition for valid values.
// Page part Multiplicity with a value that is not ZeroOrOne or Many.
table 50895 "MNC AA T895"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
        field(5; Rel; Code[20]) { TableRelation = "MNC AA T895"; }
        field(6; Lvl; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50895 "MNC AA P895"
{
    PageType = API;
    SourceTable = "MNC AA T895";
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
            part(P; "MNC AA Sub8950") { EntityName = 'sub'; EntitySetName = 'subs'; Multiplicity = Several; }
        }
    }
}
page 58950 "MNC AA Sub8950"
{
    PageType = ListPart;
    SourceTable = "MNC AA T895";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } field(Txt; Rec.Txt) { } } } }
}
