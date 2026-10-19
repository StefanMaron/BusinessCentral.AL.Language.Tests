// @expect AL0155 | A member of type Field with name 'A' is already defined in Table 'MNC Table' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type Field with name 'A' is already defined in Table 'MNC Table' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// Two table fields with one name.
table 50000 "MNC Table"
{
    fields { field(1; A; Integer) { } field(2; A; Integer) { } }
    keys { key(PK; A) { Clustered = true; } }
}
