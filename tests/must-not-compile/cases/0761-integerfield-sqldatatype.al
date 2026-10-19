// @expect AL0843 | The property 'SQLDataType' can only be used if the field's type is 'Code'.
// SQLDataType is allowed on Code fields only.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { SQLDataType = Integer; } } keys { key(PK; Id) { Clustered = true; } } }
