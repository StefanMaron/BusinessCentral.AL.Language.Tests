// @expect AL0169 | The option value 'Sometimes' is not valid. Check the enum definition for valid values.
// Same as 0765, on a table extension.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
tableextension 59990 "MNC X TE" extends "MNC X T" { AllowInCustomizations = Sometimes; fields { field(59990; E; Integer) { } } }
