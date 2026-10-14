// @expect AL0206 | A field with ID 1 is already defined in Table 'MNC Table' by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0206 | A field with ID 1 is already defined in Table 'MNC Table' by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two table fields with one id.
table 50000 "MNC Table"
{
    fields { field(1; A; Integer) { } field(1; B; Integer) { } }
    keys { key(PK; A) { Clustered = true; } }
}
