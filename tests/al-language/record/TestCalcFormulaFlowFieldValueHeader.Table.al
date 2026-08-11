/// <summary>
/// A parent FlowField ("Total Amount") whose calculated value DRIVES the where-condition of
/// other FlowFields on the same table. BC resolves such a condition by recalculating the
/// referenced FlowField first and filtering the source rows on that value — it is not a read
/// of whatever happens to sit in the record's buffer, so the dependent FlowFields answer
/// correctly even when the driver was never explicitly CalcFields'd.
/// </summary>
table 60941 "CFV Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        /// The DRIVER: a plain parent-link FlowField. 100 + 20 + 3 = 123 on D1.
        field(10; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFV Line".Amount where("Doc No." = field("No.")));
        }

        /// The DEPENDENT: the second condition compares a source column against the value of
        /// "Total Amount" — a FlowField of this same record. Only the lines whose "Ref Amount"
        /// equals the document's own total are summed.
        field(11; "Matched Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFV Line".Amount where("Doc No." = field("No."),
                                                      "Ref Amount" = field("Total Amount")));
        }

        /// The same condition driving a count(), to show it is not a sum-only code path.
        field(12; "Matched Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFV Line" where("Doc No." = field("No."),
                                                 "Ref Amount" = field("Total Amount")));
        }

        /// A FlowField whose own where-condition references ITSELF. Calculating it can only
        /// be done by calculating it, so BC refuses with its recursion error instead of
        /// recursing until the stack runs out.
        field(20; "Self Ref Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFV Line".Amount where("Doc No." = field("No."),
                                                      "Ref Amount" = field("Self Ref Amount")));
        }

        /// A pair of FlowFields whose where-conditions reference EACH OTHER. Neither one
        /// references itself, so the cycle can only be caught by bounding how deep the
        /// resolution is allowed to recurse.
        field(21; "Cycle A"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFV Line".Amount where("Doc No." = field("No."),
                                                      "Ref Amount" = field("Cycle B")));
        }

        field(22; "Cycle B"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFV Line".Amount where("Doc No." = field("No."),
                                                      "Ref Amount" = field("Cycle A")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
