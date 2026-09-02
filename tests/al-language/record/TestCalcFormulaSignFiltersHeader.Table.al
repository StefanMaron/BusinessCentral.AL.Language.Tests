/// <summary>
/// One FlowField per CalcFormula shape under test. With the seeded rows (see "CFS Tests")
/// every one of them lands on a different value, so an implementation that ignored the
/// sign, ignored the where-conditions, or returned the type default cannot satisfy them.
/// </summary>
table 60911 "CFS Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        /// The baseline: no condition beyond the parent link. 100 + 20 + 3 = 123.
        field(10; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFS Line".Amount where("Doc No." = field("No.")));
        }

        /// #1708 — the same aggregate with AL's leading sign. Must be -123, not 123 and
        /// not 0 (0 is what the refused-formula behaviour produced).
        field(11; "Negated Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -sum("CFS Line".Amount where("Doc No." = field("No.")));
        }

        /// #1709 — const() on a Boolean. Only the two Open rows: 100 + 3 = 103.
        field(12; "Open Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFS Line".Amount where("Doc No." = field("No."),
                                                     Open = const(true)));
        }

        /// #1709 — const() driving a count. Exactly one row is not Open.
        field(13; "Closed Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFS Line" where("Doc No." = field("No."),
                                                 Open = const(false)));
        }

        /// #1709 — filter() alternation on an Option field: Open|Released = 100 + 20 = 120.
        field(14; "Active Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFS Line".Amount where("Doc No." = field("No."),
                                                     Status = filter(Open | Released)));
        }

        /// #1709 — filter() range on an Integer field: entries 2..3 = 20 + 3 = 23.
        field(15; "Range Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFS Line".Amount where("Doc No." = field("No."),
                                                     "Entry No." = filter(2 .. 3)));
        }

        /// #1709, the exclusion direction — two const conditions that no row satisfies
        /// together (the only Closed row is Open). Must be 0, which only holds if BOTH
        /// conditions are applied and ANDed.
        field(16; "Unmatched Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFS Line".Amount where("Doc No." = field("No."),
                                                     Status = const(Closed),
                                                     Open = const(false)));
        }

        /// #1708 + #1709 together: the negated sum of the Released rows only = -20.
        field(17; "Negated Released Total"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -sum("CFS Line".Amount where("Doc No." = field("No."),
                                                      Status = const(Released)));
        }

        /// The exist family. An exist FlowField is Boolean by construction, while the
        /// where-condition it is built from names fields of the SOURCE table -- so the
        /// leading '-' on one of these cannot be an arithmetic negation of the source
        /// field's type. It has to be a logical NOT of the Boolean.
        ///
        /// The two negated fields below differ ONLY in the type of the first field named
        /// in the where clause: Code[20] in one, Integer in the other. That distinction is
        /// invisible to AL and must stay invisible in the answer.
        field(18; "Has Lines"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("CFS Line" where("Doc No." = field("No.")));
        }

        field(19; "Has No Lines"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = - exist("CFS Line" where("Doc No." = field("No.")));
        }

        field(20; "Has Line In Entry Range"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("CFS Line" where("Entry No." = filter(2 .. 3),
                                                 "Doc No." = field("No.")));
        }

        field(21; "Has No Line In Entry Range"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = - exist("CFS Line" where("Entry No." = filter(2 .. 3),
                                                   "Doc No." = field("No.")));
        }

        /// A negated exist over a combination no row satisfies -- the exclusion direction.
        /// Must be true, and only if BOTH conditions are applied AND the sign is honoured.
        field(22; "Has No Closed Not Open Line"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = - exist("CFS Line" where("Doc No." = field("No."),
                                                   Status = const(Closed),
                                                   Open = const(false)));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
