// @expect AL0844 | The property 'DateFormula' can only be used if the field's type is one of these values: 'Char,Code,Label,String,Text,TextConst'.
// A Date field cannot carry DateFormula = true (the property exists only on Text-like fields).
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } field(2; D; Date) { DateFormula = true; } } keys { key(PK; Id) { Clustered = true; } } }
