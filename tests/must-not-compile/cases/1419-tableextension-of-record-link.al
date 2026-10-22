// @expect AL0525 | The system or virtual table 'Record Link' cannot be extended.
// A table extension of the system table "Record Link". Corpus issue 664 item 100 (microsoft/AL#5268). Writer BO.
tableextension 51426 "MNC BO 1419" extends "Record Link"
{
    fields { field(51426; "MNC BO X"; Integer) { } }
}
