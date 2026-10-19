// @expect AL0757 | The metadata name of Field 'Timestamp' conflicts with Field 'SystemRowVersion' defined in Table 'Item'
// A table extension field named Timestamp on Item: its metadata name clashes with the system field SystemRowVersion (it no longer
// compiles and then fails at the second publish). Corpus issue 664 item 101 (microsoft/AL#6622). Writer BO.
tableextension 51427 "MNC BO 1420" extends Item
{
    fields { field(51427; Timestamp; BigInteger) { } }
}
