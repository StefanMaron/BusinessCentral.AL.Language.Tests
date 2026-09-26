// ALTSeparatorCaptionQuery: a query whose column Captions contain ';' and a leading '"', the
// characters a multi-language value uses as syntax. Used by TestRecordCaptionSeparators.
// Fixture table: ALT Separator Captioned (60026)
query 60023 "ALT Separator Caption Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Separated; "ALT Separator Captioned")
        {
            column(EntryNo; "Entry No.")
            {
                Caption = 'Column; with semicolon';
            }
            column(QuotedStart; "Quoted Start")
            {
                Caption = '"Quoted" column';
            }
        }
    }
}
