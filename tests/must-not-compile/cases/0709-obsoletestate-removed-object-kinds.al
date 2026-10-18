// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0327 | Missing file 'x.js'.
// Removed is not a value of ObsoleteState for these object kinds (it is for table fields).
codeunit 59709 "MNC U CU 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
enum 59710 "MNC U Enum 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; value(0; A) { } }
interface "MNC U Intf 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; procedure P(); }
query 59711 "MNC U Query 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; elements { dataitem(C; Customer) { column(No; "No.") { } } } }
report 59712 "MNC U Rep 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; ProcessingOnly = true; }
xmlport 59713 "MNC U Xml 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; schema { textelement(R) { } } }
page 59714 "MNC U Page 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; PageType = Card; }
controladdin "MNC U AddIn 709" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; Scripts = 'x.js'; }
