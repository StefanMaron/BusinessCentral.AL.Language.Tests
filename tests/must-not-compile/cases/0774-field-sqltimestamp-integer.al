// @expect AL0843 | The property 'SQLTimestamp' can only be used if the field's type is 'BigInteger'.
// SQLTimestamp on an Integer field.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Integer) { SQLTimestamp = true; } } keys { key(PK; Id) { Clustered = true; } } }
