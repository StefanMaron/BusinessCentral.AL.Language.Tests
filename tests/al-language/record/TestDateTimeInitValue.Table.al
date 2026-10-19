// Fixtures for TestDateTimeInitValue.Codeunit.al: a DateTime InitValue (0DT) and a closing-date
// InitValue (C20260101D), each on its own table so one shape failing cannot hide the other.
// Written by agent stma-auto2-3 (AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4794).
table 67512 "ALT DateTime Init Value"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Zero DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            InitValue = 0DT;
        }
        field(3; "Plain DateTime"; DateTime)
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

table 67513 "ALT Closing Date Init Value"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Closing Date"; Date)
        {
            DataClassification = SystemMetadata;
            InitValue = C20260101D;
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
