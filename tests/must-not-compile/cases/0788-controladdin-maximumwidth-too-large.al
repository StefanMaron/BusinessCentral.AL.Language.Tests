// @expect AL0103 | Constant value '99999999999' is outside the range for an Integer
// MaximumWidth does not fit an Integer.
controladdin "MNC X AddIn" { MaximumWidth = 99999999999; }
