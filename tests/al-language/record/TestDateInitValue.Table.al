// Fixture for TestDateInitValue.Codeunit.al: Date fields carrying an InitValue, declared on a
// table compiled from source in this app. Written by agent stma-auto2-3 (AL Runner issue
// StefanMaron/BusinessCentral.AL.Runner#4633).
table 67510 "ALT Date Init Value"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Start Date"; Date)
        {
            DataClassification = SystemMetadata;
            InitValue = 20260101D;
        }
        field(3; "Leap Date"; Date)
        {
            DataClassification = SystemMetadata;
            InitValue = 20240229D;
        }
        field(4; "Zero Date"; Date)
        {
            DataClassification = SystemMetadata;
            InitValue = 0D;
        }
        field(5; "Plain Date"; Date)
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
