// @expect AL0246 | The property 'CompressionType' cannot be customized.
// Corpus issue #668 item 82: CompressionType on a table extension.
table 51492 "MNC BS Compress"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51492 "MNC BS Compress Ext" extends "MNC BS Compress"
{
    CompressionType = Page;
}
