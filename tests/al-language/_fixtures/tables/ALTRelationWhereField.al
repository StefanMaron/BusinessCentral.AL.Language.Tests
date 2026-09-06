// Fixture for the where(... = field(...)) form of TableRelation.
//
// A relation may narrow its related table with a where() clause, and one of the shapes that
// clause can take is a link to a field of the REFERENCING row — `field(<name>)`. Base
// Application uses it heavily (Customer.City, Workflow Rule."Field No.", Overdue Approval
// Entry."Document No." are three of many), but nothing in this corpus declared one, so nothing
// pinned what FieldRef.Relation answers for such a field.
//
// In `where(A = field(B))`, A names a field of the RELATED table and B names a field of the
// REFERENCING table. The two sides are deliberately spelled apart AND numbered apart here —
// "Parent Group" is field 5 of the parent, "Child Group" is field 2 of the child — and that is
// the whole reason this fixture looks asymmetric:
//
//   * An implementation that swapped the two roles would look for "Parent Group" on the CHILD
//     and "Child Group" on the PARENT. Neither exists, so the relation cannot resolve and the
//     Validate tests fail. If both sides carried the same name, the swap would resolve to the
//     same field either way and every assertion would still pass.
//   * An implementation that carried the field NUMBERS through to the wrong table would look
//     for field 2 on the parent, which does not exist (the parent has 1 and 5). If both sides
//     carried the same number, that swap would also be invisible.
//
// So: renaming is what makes a name-based swap detectable, renumbering is what makes an
// id-based swap detectable, and neither alone is enough. The parent's group field is numbered
// 5 rather than 2 for exactly that reason — the gap is on purpose, not an accident of editing.
//
// This is the concrete case of the two-rule contract in CONTRIBUTING.md: before the fields were
// named and numbered apart, every test in TestFieldRefRelation.al passed against an
// implementation that resolved the two sides against the wrong tables.

table 60480 "ALT Rel Where Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        // Numbered 5, not 2: see the header. The child's linked field is 2, so a role swap
        // that carried numbers rather than names lands on a field number this table does not
        // declare, instead of silently landing on the right one.
        field(5; "Parent Group"; Code[20])
        {
            DataClassification = SystemMetadata;
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

table 60481 "ALT Rel Where Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        // The REFERENCING side of the field() link. Named and numbered differently from the
        // parent's "Parent Group" so the two roles cannot be confused for one another.
        field(2; "Child Group"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(3; Kind; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = A,B;
        }
        // The subject: a plain relation narrowed by a field() link.
        field(4; "Where Field Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Rel Where Parent"."Code" where("Parent Group" = field("Child Group"));
        }
        // The same shape as one arm of a conditional relation, so arm selection can be
        // asserted separately from the where() clause itself.
        field(5; "Cond Where Field Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = if (Kind = const(A)) "ALT Rel Where Parent"."Code" where("Parent Group" = field("Child Group"))
            else
            "ALT Relation Parent B"."Code";
        }
        // Control: same target table, no where() clause at all.
        field(6; "Plain Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Rel Where Parent"."Code";
        }
        // Control: no TableRelation, so Relation must answer 0.
        field(7; "No Relation"; Code[20])
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
