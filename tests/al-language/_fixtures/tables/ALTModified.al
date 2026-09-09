// ALTModified: a table whose field Captions are CHANGED by a tableextension's modify(...)
// block (ALTModifiedExt, 60499).
//
// Field 10 declares a Caption that the extension then overrides, and field 11 declares one
// the extension leaves alone. The pair is the point: a test reading field 10 alone could
// pass because captions are broken in some other direction, and field 11 is the control that
// rules that out.
table 60506 "ALT Modified"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Overridden Field"; Text[50])
        {
            Caption = 'Original Overridden Caption';
            DataClassification = SystemMetadata;
        }
        field(11; "Untouched Field"; Text[50])
        {
            Caption = 'Original Untouched Caption';
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
