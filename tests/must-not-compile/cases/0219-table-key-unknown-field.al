// @expect AL0186 | Reference 'NoSuchField' in application object 'MNC T219' does not exist
// @expect AL0306 | A field list has to contain at least one field
// A table key names a field the table does not have.
table 50024 "MNC T219"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; NoSuchField) { Clustered = true; } }
}
