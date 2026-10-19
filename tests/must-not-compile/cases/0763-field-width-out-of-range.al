// @expect AL0103 | Constant value '99999999999' is outside the range for an Integer
// Width on a table field with a value that does not fit an Integer.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { Width = 99999999999; } } keys { key(PK; Id) { Clustered = true; } } }
