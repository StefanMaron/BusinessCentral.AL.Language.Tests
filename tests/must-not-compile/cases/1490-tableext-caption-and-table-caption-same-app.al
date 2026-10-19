// @expect AL0839 | The symbol 'Caption' has same trans unit ID in Text Data XLIFF file as one or more other symbols.
// @expect AL0839 | The symbol 'Caption' has same trans unit ID in Text Data XLIFF file as one or more other symbols.
// Corpus issue #668 item 81: Caption on a table extension. Alone it compiles (tests/al-language/tableextension/TestTableExtFieldModify.al,
// TableExt_CaptionProperty_TableCaptionAndMetadata); when the extended table of the same app also sets Caption, both Caption symbols get
// the same XLIFF trans-unit id (one diagnostic per declaration).
table 51490 "MNC BS Cap"
{
    Caption = 'MNC BS Table Caption';
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 51490 "MNC BS Cap Ext" extends "MNC BS Cap"
{
    Caption = 'MNC BS Extension Caption';
}
