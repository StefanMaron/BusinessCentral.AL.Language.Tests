table 60028 "ALT Relation Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
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

table 60029 "ALT Relation Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Validated Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Relation Parent"."Code";
        }
        field(3; "Unvalidated Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Relation Parent"."Code";
            ValidateTableRelation = false;
        }
        field(4; "Soft Ref"; Code[20])
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
