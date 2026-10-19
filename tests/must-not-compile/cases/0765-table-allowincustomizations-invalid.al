// @expect AL0169 | The option value 'Sometimes' is not valid. Check the enum definition for valid values.
// AllowInCustomizations takes ToBeClassified, Never, AsReadOnly or AsReadWrite.
table 59990 "MNC X T" { AllowInCustomizations = Sometimes; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
