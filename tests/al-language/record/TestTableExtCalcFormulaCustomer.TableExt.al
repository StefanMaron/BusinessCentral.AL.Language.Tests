// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Customer (18), Value Entry (5802), Item Ledger Entry (32), TXC ILE Ext (60822)
//
// A tableextension may name its OWN added fields inside a CalcFormula, on both sides of the
// link:
//
//   * a `where(... = field(<X>))` arm whose parent field X is a FlowFilter this extension
//     added to the extended table,
//   * a `sum(<Target>.<Y> ...)` whose source field Y is a field another tableextension added
//     to the TARGET table,
//   * a `where(<Y> = const(...))` arm over such a field on the target table.
//
// The two controls in this extension are what make the claim about extension fields rather
// than about CalcFormula in general: "TXC Sales Base Filter" is the same formula shape with
// Customer's own base-app "Date Filter" FlowFilter substituted for the extension one, and
// "TXC Sales Amount Total" carries the plain `field("No.")` arm alone.
tableextension 60821 "TXC Cust Stats Ext" extends Customer
{
    fields
    {
        field(60821; "TXC Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }
        field(60822; "TXC Item Filter"; Code[20])
        {
            FieldClass = FlowFilter;
        }

        // Control: the base-app arm alone, no flow filter referenced at all.
        field(60823; "TXC Sales Amount Total"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Source No." = field("No.")));
        }

        // A where-arm whose PARENT field is a FlowFilter this extension added.
        field(60824; "TXC Sales Amount"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Source No." = field("No."),
                                                                          "Posting Date" = field("TXC Date Filter")));
        }

        // Two extension FlowFilters in one formula.
        field(60825; "TXC Sales By Item"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Source No." = field("No."),
                                                                          "Posting Date" = field("TXC Date Filter"),
                                                                          "Item No." = field("TXC Item Filter")));
        }

        // The SOURCE field is a field a second tableextension added to the target table.
        field(60826; "TXC Weight"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("Item Ledger Entry"."TXC Ext Weight" where("Source No." = field("No.")));
        }

        // A where-arm over a field a second tableextension added to the target table.
        field(60827; "TXC Qty Heavy"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Source No." = field("No."),
                                                                 "TXC Ext Weight" = const(7.5)));
        }

        // Control: same shape as "TXC Sales Amount", but the FlowFilter is Customer's own.
        field(60828; "TXC Sales Base Filter"; Decimal)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Source No." = field("No."),
                                                                          "Posting Date" = field("Date Filter")));
        }
    }
}
