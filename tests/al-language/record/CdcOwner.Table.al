/// <summary>
/// The PARENT side: FlowFields and a TableRelation whose where() clause pins an Integer
/// column with <c>const(Database::&lt;Table&gt;)</c>.
/// <para>Both properties carry the same constant in the same position, so one fixture
/// covers both places AL's object-reference syntax can appear in a where() clause. The two
/// constants used — <c>Database::"CDC Owner"</c> (60328) and <c>Database::"CDC Ref Row"</c>
/// (60327) — are different numbers, so a formula that resolved BOTH to the same thing (or to
/// neither) cannot answer the seeded counts.</para>
/// </summary>
table 60328 "CDC Owner"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }

        /// exist() narrowed by the constant: true only while a row carrying THIS table's id
        /// exists for this owner.
        field(10; "Owns Owner Rows"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("CDC Ref Row" where("Owner No." = field("No."),
                                                    "Table ID" = const(Database::"CDC Owner")));
        }

        /// count() over the same condition — a number, so a wrong id set is visible as a
        /// wrong count rather than only as true/false.
        field(11; "Owner Row Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CDC Ref Row" where("Owner No." = field("No."),
                                                    "Table ID" = const(Database::"CDC Owner")));
        }

        /// The SAME shape pinned to the OTHER table's id. Its value must differ from
        /// "Owner Row Count" on the seeded data, which no single mis-resolution can produce.
        field(12; "Ref Row Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("CDC Ref Row" where("Owner No." = field("No."),
                                                    "Table ID" = const(Database::"CDC Ref Row")));
        }

        /// sum() over the constant-narrowed rows, so the aggregate paths are covered too.
        field(13; "Owner Row Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("CDC Ref Row".Amount where("Owner No." = field("No."),
                                                         "Table ID" = const(Database::"CDC Owner")));
        }

        /// A TableRelation narrowed by the same constant: only "CDC Ref Row" rows carrying
        /// THIS table's id are valid values.
        field(20; "Pinned Ref"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "CDC Ref Row"."Code" where("Table ID" = const(Database::"CDC Owner"));
        }

        /// Control: same target table, no where() clause, so any existing "Code" is valid.
        /// Without it, a refusal on "Pinned Ref" could just mean the relation is broken.
        field(21; "Plain Ref"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "CDC Ref Row"."Code";
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
