// @expect AL0169 | The option value 'Hidden' is not valid. Check the enum definition for valid values.
// MaskType takes None or Concealed.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { MaskType = Hidden; } } keys { key(PK; Id) { Clustered = true; } } }
