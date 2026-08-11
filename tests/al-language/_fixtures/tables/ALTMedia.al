// ALTMedia: Media / MediaSet field type fixture.
// "Picture" (Media) is the control case — a single media value directly on the field.
// "Images" (MediaSet) is under test — a collection of media values sharing one field.
table 60980 "ALT Media"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Description"; Text[100])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Picture"; Media)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Images"; MediaSet)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
