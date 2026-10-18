// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteReason' can only be used if the property 'ObsoleteState' is set to 'Pending'
// @expect AL0223 | The Property 'ObsoleteTag' can only be used if the property 'ObsoleteState' is set to 'Pending'
// ObsoleteReason and ObsoleteTag need ObsoleteState = Pending, on every object kind.
codeunit 59713 "MNC U CU 713" { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
enum 59714 "MNC U Enum 713" { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; value(0; A) { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } }
query 59715 "MNC U Query 713" { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; elements { dataitem(C; Customer) { column(No; "No.") { } } } }
report 59716 "MNC U Rep 713" { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; ProcessingOnly = true; }
xmlport 59717 "MNC U Xml 713" { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; schema { textelement(R) { } } }
page 59718 "MNC U Page 713" { ObsoleteReason = 'r'; ObsoleteTag = '1.0'; PageType = Card; }
