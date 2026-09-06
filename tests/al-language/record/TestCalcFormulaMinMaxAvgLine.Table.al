/// <summary>
/// The source table the min()/max()/average() FlowFields in "CFM Header" aggregate.
///
/// The seeded rows (see "CFM Tests") are chosen so that the smallest Amount is NEGATIVE, the
/// largest is neither the sum nor the row count, and the average does not divide evenly. One
/// document is seeded with three zero-Amount rows so that "skips blank source values" and
/// "counts every matching row" give DIFFERENT answers for both min() and average().
/// </summary>
table 60440 "CFM Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc No."; Code[20]) { }

        /// The Decimal aggregation source. Deliberately includes a negative value, so an
        /// implementation that seeds its running minimum with zero cannot pass.
        field(3; Amount; Decimal) { }

        /// The Integer aggregation source: min()/max() are shown not to be a Decimal-only
        /// code path, and average() over an Integer is shown not to truncate to an Integer.
        field(4; Quantity; Integer) { }

        /// The Date aggregation source — the "first / last date" shape BC's own
        /// "Job Task"."Starting Date" uses.
        field(5; "Posting Date"; Date) { }

        /// A DURATION aggregation source. Duration is one of the four types BC will sum or
        /// average, so a Duration source separates "this type cannot be aggregated at all"
        /// from "this aggregate's FlowField is typed differently from its source" -- the two
        /// refusals "CFM Validation Tests" has to tell apart.
        field(6; Elapsed; Duration) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
