/// <summary>
/// One FlowField per flow-filter CalcFormula shape under test, plus the unfiltered baseline.
/// With the seeded rows (see "CFF Tests") every shape lands on a different value, so an
/// implementation that drops the where-condition, applies it as a plain equality, or confuses
/// <c>upperlimit()</c> with <c>filter()</c> cannot satisfy them all.
/// </summary>
table 60931 "CFF Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        /// A FlowFilter field: it stores nothing and never constrains this table itself —
        /// it exists only so the FlowFields below can read the caller's SetRange/SetFilter.
        field(2; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }

        /// A NORMAL text field whose VALUE is a filter expression, the "G/L Account".Totaling
        /// shape. field(filter(...)) reads this value, not the caller's filters.
        field(3; "Account Totaling"; Text[250]) { }

        /// The same idea aimed at a source field that another where-condition already
        /// constrains — see "Doc Totaling Amount".
        field(4; "Doc Totaling"; Text[250]) { }

        /// The baseline: only the parent link, no flow filter. 100 + 20 + 3 = 123 on D1.
        field(10; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFF Line".Amount where("Doc No." = field("No.")));
        }

        /// field(<FlowFilter field>) — the caller's whole filter on "Date Filter" is applied
        /// to "Posting Date". No filter set means no constraint, not "blank date".
        field(11; "Period Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFF Line".Amount where("Doc No." = field("No."),
                                                      "Posting Date" = field("Date Filter")));
        }

        /// field(upperlimit(<FlowFilter field>)) — only the UPPER bound of the caller's range
        /// is applied, so rows before the range's start are still counted.
        field(12; "Balance at Date"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFF Line".Amount where("Doc No." = field("No."),
                                                      "Posting Date" = field(upperlimit("Date Filter"))));
        }

        /// The same flow filter driving a count, to show it is not a sum-only code path.
        field(13; "Period Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CFF Line" where("Doc No." = field("No."),
                                                 "Posting Date" = field("Date Filter")));
        }

        /// field(filter(<Normal field>)) — the parent field's VALUE is parsed as a filter
        /// expression over "Account No.", so 'A1' selects rows and 'A1|A2' widens.
        field(14; "Totaling Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFF Line".Amount where("Doc No." = field("No."),
                                                      "Account No." = field(filter("Account Totaling"))));
        }

        /// Two conditions on the SAME source field: a plain link and a filter(). This is the
        /// "G/L Account".Totaling shape, where the totaling filter is meant to take over from
        /// the account's own entries.
        field(15; "Doc Totaling Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CFF Line".Amount where("Doc No." = field("No."),
                                                      "Doc No." = field(filter("Doc Totaling"))));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
