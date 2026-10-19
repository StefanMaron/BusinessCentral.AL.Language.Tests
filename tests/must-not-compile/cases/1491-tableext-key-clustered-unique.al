// @expect AL0404 | Property 'Clustered' is not allowed on a table extension.
// @expect AL0404 | Property 'Unique' is not allowed on a table extension.
// Corpus issue #668 item 82: Clustered and Unique on a key that a table extension adds. MaintainSqlIndex = false on such a key compiles.
table 51491 "MNC BS Keys"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51491 "MNC BS Keys Ext" extends "MNC BS Keys"
{
    fields
    {
        field(51491; E1; Integer) { }
        field(51492; E2; Integer) { }
        field(51493; E3; Integer) { }
    }
    keys
    {
        key(K1; E1) { Clustered = true; }
        key(K2; E2) { Unique = true; }
        key(K3; E3) { MaintainSqlIndex = false; }
    }
}
