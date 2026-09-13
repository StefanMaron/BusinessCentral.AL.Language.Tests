// Fixture for a TableRelation declared on a field that is not FieldClass = Normal.
//
// A FlowFilter and a FlowField may both declare a TableRelation. Neither stores a value, so
// neither takes part in rename propagation (BC skips non-Normal referencing fields there), but
// the relation is still part of the field's metadata: FieldRef.Relation answers it and
// Validate checks it. Nothing in this corpus declared either shape.
//
// Every relation here targets "ALT Rel Where Parent" (60480) or "ALT Relation Parent B"
// (60030), so the two arms of the conditional field answer different ids.

table 60483 "ALT Rel Field Class"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Kind; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = A,B;
        }
        field(3; "Filter Ref"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = "ALT Rel Where Parent"."Code";
        }
        field(4; "Cond Filter Ref"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = if (Kind = const(A)) "ALT Rel Where Parent"."Code"
            else
            "ALT Relation Parent B"."Code";
        }
        // Same relation as "Filter Ref", with the check switched off.
        field(5; "Filter Ref No Validate"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = "ALT Rel Where Parent"."Code";
            ValidateTableRelation = false;
        }
        field(6; "Flow Ref"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("ALT Rel Where Parent"."Code" where("Code" = field("Filter Ref")));
            TableRelation = "ALT Rel Where Parent"."Code";
        }
        // Control: a FlowFilter with no TableRelation.
        field(7; "Filter No Relation"; Code[20])
        {
            FieldClass = FlowFilter;
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
