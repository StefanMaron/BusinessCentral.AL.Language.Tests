// @expect AL0264 | An application object of type 'Codeunit' with ID '50000' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Codeunit' with ID '50000' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// The same object id used by two objects of one type.
codeunit 50000 "MNC First" { }
codeunit 50000 "MNC Second" { }
