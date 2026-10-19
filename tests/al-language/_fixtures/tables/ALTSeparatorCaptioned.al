// ALTSeparatorCaptioned: a table whose declared captions contain the characters a
// multi-language string uses as syntax -- ';' ends a language entry, '=' separates the
// language tag from its text, and a value opening with '"' is a quoted one. Each caption
// must still come back whole, exactly as declared. Used by TestRecordCaptionSeparators.
//
// ALTSeparatorCaptionedExt changes field 4's Caption through modify(...), so this table's
// caption also reaches AL through an extension's delta, not only through its own declaration.
table 60026 "ALT Separator Captioned"
{
    Caption = 'Before; after';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Left; right';
            DataClassification = SystemMetadata;
        }
        field(2; "Quoted Start"; Text[50])
        {
            Caption = '"Quoted" start';
            DataClassification = SystemMetadata;
        }
        field(3; "Equals Sign"; Integer)
        {
            Caption = 'Rate = 5%';
            DataClassification = SystemMetadata;
        }
        field(4; "Modified Field"; Integer)
        {
            Caption = 'Original caption';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
