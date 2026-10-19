// @expect AL0169 | The option value 'Hidden' is not valid. Check the enum definition for valid values.
// modify() of a field with an invalid MaskType value.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { } } keys { key(PK; Id) { Clustered = true; } } }
tableextension 59990 "MNC X TE" extends "MNC X T" { fields { modify(T) { MaskType = Hidden; } } }
