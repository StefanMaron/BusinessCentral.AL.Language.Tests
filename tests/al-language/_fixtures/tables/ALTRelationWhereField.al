// Fixture for the where(... = field(...)) form of TableRelation.
//
// A relation may narrow its related table with a where() clause, and one of the shapes that
// clause can take is a link to a field of the REFERENCING row — `field(<name>)`. Base
// Application uses it heavily (Customer.City, Workflow Rule."Field No.", Overdue Approval
// Entry."Document No." are three of many), but nothing in this corpus declared one, so nothing
// pinned what FieldRef.Relation answers for such a field.
//
// "ALT Rel Where Parent" carries a Group Code so the where() clause has a real column to
// narrow on, and the child's "Group Code" is what the field() link reads.

table 60480 "ALT Rel Where Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Group Code"; Code[20])
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
        field(2; "Group Code"; Code[20])
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
            TableRelation = "ALT Rel Where Parent"."Code" where("Group Code" = field("Group Code"));
        }
        // The same shape as one arm of a conditional relation, so arm selection can be
        // asserted separately from the where() clause itself.
        field(5; "Cond Where Field Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = if (Kind = const(A)) "ALT Rel Where Parent"."Code" where("Group Code" = field("Group Code"))
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
