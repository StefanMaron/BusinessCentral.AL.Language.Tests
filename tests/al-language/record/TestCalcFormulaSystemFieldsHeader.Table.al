/// <summary>
/// FlowFields whose CalcFormula names one of BC's system fields, plus the ordinary-field
/// baselines they have to be contrasted against.
///
/// A CalcFormula can name a system field in three different positions, and each one is a
/// separate resolution site:
///
///   * as the PARENT field a where-arm links to        — where("Header Sys Id" = field(SystemId))
///   * as the aggregated SOURCE field                  — max("CFSF Line".SystemCreatedAt ...)
///   * as the SOURCE-TABLE field a where-arm filters   — where(SystemCreatedBy = field("Owner Id"))
///
/// The seeded rows (see "CFSF Tests") make every one of these land on a value that is wrong
/// for a formula whose system-field where-arm was dropped: three lines share "Doc No." = 'D1'
/// and only two of them carry the header's SystemId, so "Line Count By Sys Id" is 2 while the
/// ordinary-field baseline "Line Count" is 3.
/// </summary>
table 60816 "CFSF Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        /// Set by the test to a value read back from a line's SystemCreatedBy, or to an
        /// unrelated GUID for the negative arm.
        field(2; "Owner Id"; Guid) { }

        /// Baselines over ordinary fields. With the seeded rows these are 3 and 1025, and no
        /// system-field answer below is allowed to equal either.
        field(10; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFSF Line" where("Doc No." = field("No.")));
        }

        field(11; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFSF Line".Amount where("Doc No." = field("No.")));
        }

        /// The where-arm's PARENT side is a system field. Two of D1's three lines carry the
        /// header's SystemId, so this is 2 — not 3 (the arm dropped) and not 0.
        field(12; "Line Count By Sys Id"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFSF Line" where("Header Sys Id" = field(SystemId)));
        }

        /// The same link, aggregating an amount rather than counting: 125, not 1025.
        field(13; "Amount By Sys Id"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFSF Line".Amount where("Header Sys Id" = field(SystemId)));
        }

        /// The aggregated SOURCE field is a system field.
        field(14; "Last Line Created At"; DateTime)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFSF Line".SystemCreatedAt where("Doc No." = field("No.")));
        }

        field(15; "First Line Created At"; DateTime)
        {
            FieldClass = FlowField;
            CalcFormula = min("CFSF Line".SystemCreatedAt where("Doc No." = field("No.")));
        }

        /// A looked-up system field.
        field(16; "Line Created By"; Guid)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CFSF Line".SystemCreatedBy where("Doc No." = field("No.")));
        }

        /// The where-arm's SOURCE-TABLE side is a system field: all three lines were created
        /// by the running user, so this is 3 when "Owner Id" holds that user and 0 otherwise.
        field(17; "Line Count By Creator"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFSF Line" where(SystemCreatedBy = field("Owner Id")));
        }

        /// A TableRelation whose TARGET is a system field — the shape an API page's foreign
        /// key uses. Validating it must accept an existing line's SystemId and refuse a GUID
        /// no line carries.
        field(20; "Line Sys Id"; Guid)
        {
            TableRelation = "CFSF Line".SystemId;
        }

        /// SystemRowVersion is the SIXTH system field, and it is unlike the other five: the
        /// AL compiler synthesizes it at field id 0 with metadata name `timestamp`, not in
        /// the 2000000000-2000000004 block. So naming it in a formula exercises a resolution
        /// path the fields above cannot reach, and these arms say what BC answers there.
        ///
        /// Aggregated as the SOURCE field. Every line has a distinct, increasing rowversion,
        /// so max() over the D1 lines is the LAST line's — strictly greater than min() over
        /// the same set, which is what makes a dropped where-arm visible: it would widen the
        /// set rather than change the ordering.
        field(30; "Last Line Row Version"; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFSF Line".SystemRowVersion where("Doc No." = field("No.")));
        }

        field(31; "First Line Row Version"; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = min("CFSF Line".SystemRowVersion where("Doc No." = field("No.")));
        }

        /// The same source field reached through a where-arm that links to the parent's
        /// SystemId, so only two of D1's three lines are in scope. With the seeded rows the
        /// answer is line 2's rowversion — NOT line 3's, which is what a dropped arm gives.
        field(32; "Row Version By Sys Id"; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = max("CFSF Line".SystemRowVersion where("Header Sys Id" = field(SystemId)));
        }

        /// A looked-up SystemRowVersion, the third position the five system fields already
        /// cover for SystemCreatedBy.
        field(33; "Line Row Version"; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("CFSF Line".SystemRowVersion where("Entry No." = field("Probe Entry No.")));
        }

        /// The parent side of the where-arm carries the value being matched. Kept an ordinary
        /// field so this arm isolates the SOURCE-side resolution above.
        field(34; "Probe Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
