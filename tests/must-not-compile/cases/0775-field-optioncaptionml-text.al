// @expect AL0843 | The property 'OptionCaptionML' can only be used if the field's type is 'Option'.
// OptionCaptionML on a Text field.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; T; Text[30]) { OptionCaptionML = ENU = 'a,b'; } } keys { key(PK; Id) { Clustered = true; } } }
