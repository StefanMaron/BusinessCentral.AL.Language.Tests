table 60024 "ALT Init Value"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Status"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 1;
        }
        field(3; "Name"; Text[50])
        {
            DataClassification = SystemMetadata;
            InitValue = 'Default';
        }
        field(4; "Active"; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(5; "Amount"; Decimal)
        {
            DataClassification = SystemMetadata;
            InitValue = 9.99;
        }
        field(6; "Plain"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Start Time"; Time)
        {
            DataClassification = SystemMetadata;
            InitValue = 120000T;
        }
        field(8; "Midnight Time"; Time)
        {
            DataClassification = SystemMetadata;
            InitValue = 000000T;
        }
        field(9; "Plain Time"; Time)
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
