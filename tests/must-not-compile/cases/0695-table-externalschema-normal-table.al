// @expect AL0167 | The Property 'ExternalSchema' can only be used if the property 'TableType' is set with any of the values of: 'CRM,ExternalSQL,CDS'
// ExternalSchema needs TableType CRM, ExternalSQL or CDS.
table 59695 "MNC U 695"
{
    ExternalSchema = 'dbo';
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
