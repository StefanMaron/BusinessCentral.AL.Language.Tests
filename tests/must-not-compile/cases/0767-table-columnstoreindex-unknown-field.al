// @expect AL0186 | Reference 'Missing' in application object 'MNC X T' does not exist
// ColumnStoreIndex names a field the table does not have.
table 59990 "MNC X T" { ColumnStoreIndex = Id, Missing; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
