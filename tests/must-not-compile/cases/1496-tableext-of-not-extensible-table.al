// @expect AL0564 | The object Table 'MNC BS Sealed' is not extensible
// Corpus issue #668 item 84: a table extension of a table with Extensible = false.
table 51496 "MNC BS Sealed"
{
    Extensible = false;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51496 "MNC BS Sealed Ext" extends "MNC BS Sealed"
{
    fields { field(51496; SX; Integer) { } }
}
