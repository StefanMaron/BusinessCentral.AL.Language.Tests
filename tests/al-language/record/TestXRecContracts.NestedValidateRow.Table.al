// Fixture for TestXRecContracts.al's nested-Validate tests. Deliberately its OWN pair of
// tables (not the shared ALT Triggered / ALT Trigger Log fixture): only this codeunit's two
// nested-Validate tests write to them, so Initialize() can freely DeleteAll() without touching
// state another suite counts on.
table 60988 "Nested Validate Row"
{
    fields
    {
        field(1; "Code"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Kind; Option)
        {
            OptionMembers = First,Second;
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                // The nested call under test: BC's compiled AL for this trigger calls
                // Rec.Validate(Ref, ...) on the SAME NavRecord instance that is already
                // mid-Validate for Kind.
                Validate(Ref, '');
            end;
        }
        field(3; Ref; Code[20])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Record "Nested Validate Log";
            begin
                Log."Old Kind" := xRec.Kind;
                Log."Old Ref" := xRec.Ref;
                Log."New Ref" := Rec.Ref;
                Log.Insert();
            end;
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

table 60989 "Nested Validate Log"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Old Kind"; Option)
        {
            OptionMembers = First,Second;
            DataClassification = SystemMetadata;
        }
        field(3; "Old Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(4; "New Ref"; Code[20])
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
