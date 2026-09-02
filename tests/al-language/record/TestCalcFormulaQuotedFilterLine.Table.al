// Support table for TestCalcFormulaQuotedFilterTests.Codeunit.al -- the rows the
// FlowFields on "CFQ Header" aggregate over.
table 60304 "CFQ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Header No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Entry Type"; Enum "CFQ Entry Type")
        {
            DataClassification = SystemMetadata;
        }
        field(4; Amount; Decimal)
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
