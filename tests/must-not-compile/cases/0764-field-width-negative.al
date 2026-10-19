// @expect AL0232 | The property value on field 'Width' must be positive or zero.
// Width with a negative value.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { Width = -5; } } keys { key(PK; Id) { Clustered = true; } } }
