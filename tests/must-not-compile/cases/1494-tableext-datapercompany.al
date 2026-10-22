// @expect AL0246 | The property 'DataPerCompany' cannot be customized.
// Corpus issue #668 item 83: DataPerCompany on a table extension.
table 51494 "MNC BS Per Company"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51494 "MNC BS Per Company Ext" extends "MNC BS Per Company"
{
    DataPerCompany = false;
}
