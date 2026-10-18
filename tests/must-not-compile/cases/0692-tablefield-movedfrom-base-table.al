// @expect AL0825 | It is not possible to move the field 'Txt' (2) to a base table
// MovedFrom on a field of a base table (not of a table extension).
table 59692 "MNC U 692"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { MovedFrom = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5f6'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
