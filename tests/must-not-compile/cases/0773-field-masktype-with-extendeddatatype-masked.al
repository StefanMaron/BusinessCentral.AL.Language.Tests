// @expect AL0876 | The Property 'MaskType' cannot be used if the property 'ExtendedDataType' is set to 'Masked'
// MaskType = Concealed together with ExtendedDatatype = Masked.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { MaskType = Concealed; ExtendedDatatype = Masked; } } keys { key(PK; Id) { Clustered = true; } } }
