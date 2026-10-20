// @expect AL0404 | Property 'AutoIncrement' is not allowed on a table extension.
// A table extension field with AutoIncrement = true. Corpus issue 664 item 95 (microsoft/AL#1997). Writer BO.
tableextension 51421 "MNC BO 1415" extends Customer
{
    fields { field(51421; "MNC BO No"; Integer) { AutoIncrement = true; } }
}
