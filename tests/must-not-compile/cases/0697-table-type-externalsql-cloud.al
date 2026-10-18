// @expect AL0447 | The value 'ExternalSQL' for the property 'TableType' cannot be used for 'Cloud' development.
// TableType ExternalSQL cannot be used for Cloud development (ExternalSchema is meant for it).
table 59697 "MNC U 697"
{
    TableType = ExternalSQL;
    ExternalSchema = 'dbo';
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
