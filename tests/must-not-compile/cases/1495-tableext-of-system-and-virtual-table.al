// @expect AL0525 | The system or virtual table 'User' cannot be extended.
// @expect AL0525 | The system or virtual table 'Integer' cannot be extended.
// Corpus issue #668 item 84: a table extension of the system table User (2000000120) and of the virtual table Integer (2000000026).
tableextension 51495 "MNC BS User Ext" extends User
{
    fields { field(51495; UX; Integer) { } }
}

tableextension 51496 "MNC BS Integer Ext" extends Integer
{
    fields { field(51496; IX; Integer) { } }
}
