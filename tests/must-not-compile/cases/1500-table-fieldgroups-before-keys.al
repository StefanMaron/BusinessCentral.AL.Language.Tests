// @expect AL0926 | The 'keys' section is not valid here. In a table object, the expected section order is: fields, keys, fieldgroups.
// Corpus issue #668 item 86: a table that declares fieldgroups before keys. (Two table extensions that both addlast the same field to the
// DropDown group, and the spelling 'dropdown', compile.)
table 51500 "MNC BS Order"
{
    fields { field(1; Id; Integer) { } }
    fieldgroups { fieldgroup(DropDown; Id) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
