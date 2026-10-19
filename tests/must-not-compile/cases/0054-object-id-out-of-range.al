// @expect AL0297 | The application object identifier '50500' is not valid. It must be within the allowed ranges '[50000..50099]'.
// An object id outside the app idRanges.
// @appjson {"idRanges": [{"from": 50000, "to": 50099}]}
codeunit 50500 "MNC Out Of Range"
{
}
