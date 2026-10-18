// @expect AL0103 | Constant value '99999999999' is outside the range for an Integer
// modify() of a field with a Width out of range.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { } } keys { key(PK; Id) { Clustered = true; } } }
tableextension 59990 "MNC X TE" extends "MNC X T" { fields { modify(T) { Width = 99999999999; } } }
