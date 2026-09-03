// ALTCaptioned: a table whose object name and declared Caption differ.
// Every other fixture table either declares no Caption or would make a caption
// test pass by accident, because the caption and the name would be the same
// string. Used to prove that TableCaption() reads the declared Caption and
// TableName() still reads the object name.
table 60830 "ALT Captioned"
{
    Caption = 'Captioned Fixture Table';

    fields
    {
        field(1; "Entry No."; Integer)
        {
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
