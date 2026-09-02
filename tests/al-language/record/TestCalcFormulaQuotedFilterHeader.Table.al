// Support table for TestCalcFormulaQuotedFilterTests.Codeunit.al.
//
// Every FlowField here writes a CalcFormula `filter(...)` condition whose value is an
// AL quoted identifier -- a member name with a space, one with parentheses, an
// alternation mixing a quoted and an unquoted name, and a negated blank member.
table 60303 "CFQ Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Initial Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFQ Line".Amount where("Header No." = field("No."), "Entry Type" = filter("Initial Entry")));
            Editable = false;
        }
        field(11; "Discount Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFQ Line".Amount where("Header No." = field("No."), "Entry Type" = filter("Payment Discount (VAT Excl.)")));
            Editable = false;
        }
        field(12; "Alternation Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFQ Line".Amount where("Header No." = field("No."), "Entry Type" = filter(Application | "Initial Entry")));
            Editable = false;
        }
        field(13; "Non Blank Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFQ Line".Amount where("Header No." = field("No."), "Entry Type" = filter(<> " ")));
            Editable = false;
        }
        field(14; "Blank Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFQ Line" where("Header No." = field("No."), "Entry Type" = filter(" ")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
