// @expect AL0404 | Property 'SqlTimestamp' is not allowed on a table extension.
// Corpus issue #668 items 79 and 88: SqlTimestamp = true on a BigInteger field that a table extension adds. On a field of a table it
// compiles and reads the row version (tests/al-language/record/lt-x-table-props/XTablePropsTests.al, SQLTimestamp_BigIntegerField_ReadsRowVersion).
table 51498 "MNC BS Stamp"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51498 "MNC BS Stamp Ext" extends "MNC BS Stamp"
{
    fields
    {
        field(51498; Ts; BigInteger) { SqlTimestamp = true; }
    }
}
