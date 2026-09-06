/// <summary>
/// One FlowField per min()/max()/average() CalcFormula shape under test, plus the sum()/count()
/// baselines the corpus already pins.
///
/// With the seeded rows (see "CFM Tests") every one of these lands on a DIFFERENT value, so an
/// implementation that returns the sum for min, the type default for max, or an integer-divided
/// average cannot satisfy them all.
/// </summary>
table 60441 "CFM Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        /// A FlowFilter field: it stores nothing and never constrains this table itself —
        /// it exists so the "Period ..." FlowFields below can read the caller's SetRange.
        field(2; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }

        /// Baselines. Already-pinned shapes, here only so the min/max/average answers can be
        /// contrasted against them: for D1 these are 125 and 4, and no min/max/average answer
        /// below is allowed to equal either.
        field(10; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFM Line".Amount where("Doc No." = field("No.")));
        }

        field(11; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFM Line" where("Doc No." = field("No.")));
        }

        /// min() over a Decimal source. D1's smallest Amount is NEGATIVE, so 0 — the type
        /// default, and the value a running minimum seeded at zero would give — is wrong.
        field(12; "Min Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = min("CFM Line".Amount where("Doc No." = field("No.")));
        }

        /// max() over a Decimal source.
        field(13; "Max Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFM Line".Amount where("Doc No." = field("No.")));
        }

        /// average() over a Decimal source. D1 gives 31.25 — not the sum, not zero, and not
        /// an integer, so a truncating implementation fails.
        field(14; "Average Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = average("CFM Line".Amount where("Doc No." = field("No.")));
        }

        /// The same three methods over an INTEGER source, into fields typed to match. This is
        /// the pair that separates "min/max is a Decimal-only path" from a real aggregate.
        field(15; "Min Quantity"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = min("CFM Line".Quantity where("Doc No." = field("No.")));
        }

        field(16; "Max Quantity"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFM Line".Quantity where("Doc No." = field("No.")));
        }

        // average() of an Integer source into a DECIMAL FlowField -- deliberately MISTYPED,
        // and kept that way on purpose.
        //
        // BC refuses this shape, and it refuses it at CALCULATION time rather than at compile
        // time: alc 17.0.34.45391 emits no diagnostic for it, the extension publishes, and
        // CalcFields then errors with
        //
        //     The following fields must have the same type:
        //
        //     Field: Average Quantity <-- Quantity
        //     Table: CFM Header <-- CFM Line
        //     Type: Decimal <-- Integer
        //
        // measured on all eight BC legs (27.0 through 28.4). This field exists ONLY so that
        // "CFM Tests".Record_CalcFields_Average_FlowFieldTypeDiffersFromSource_Throws can pin
        // that refusal against the exact message text. Never calculate it from a positive
        // test -- the legal spelling is "Average Quantity Int" (field 23).
        field(17; "Average Quantity"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = average("CFM Line".Quantity where("Doc No." = field("No.")));
        }

        /// min()/max() over a DATE source — the "first / last date" shape. The two must land
        /// on different dates, and on 0D when nothing matches.
        field(18; "First Posting Date"; Date)
        {
            FieldClass = FlowField;
            CalcFormula = min("CFM Line"."Posting Date" where("Doc No." = field("No.")));
        }

        field(19; "Last Posting Date"; Date)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFM Line"."Posting Date" where("Doc No." = field("No.")));
        }

        /// The same three methods driven by the flow filter, so narrowing the caller's filter
        /// has to move the minimum, the maximum AND the average's DENOMINATOR.
        field(20; "Period Min Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = min("CFM Line".Amount where("Doc No." = field("No."),
                                                     "Posting Date" = field("Date Filter")));
        }

        field(21; "Period Max Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFM Line".Amount where("Doc No." = field("No."),
                                                     "Posting Date" = field("Date Filter")));
        }

        field(22; "Period Average Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = average("CFM Line".Amount where("Doc No." = field("No."),
                                                         "Posting Date" = field("Date Filter")));
        }

        /// average() over an Integer source into an Integer FlowField -- the LEGAL spelling of
        /// field 17, and the one that shows min()/max()/average() are not a Decimal-only code
        /// path. D1's quantities are 3, 4, 6 and 8, so this lands on 5: not the sum (21), not
        /// the row count (4), not the minimum (3) and not the maximum (8).
        ///
        /// Because BC requires a FlowField and its source field to share a type, an
        /// Integer-source average can never be observed as a fraction. Whether the aggregate
        /// is truncated or rounded on its way into the Integer field is therefore not askable
        /// here -- 21 / 4 = 5.25 gives 5 either way -- and the "average() is not integer
        /// division" claim is carried by the Decimal source instead (field 14: 125 / 4 = 31.25).
        field(23; "Average Quantity Int"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = average("CFM Line".Quantity where("Doc No." = field("No.")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
