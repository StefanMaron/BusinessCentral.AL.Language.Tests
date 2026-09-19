// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Host (60565), TRL Related (60563)
//
// Host table for the TableRelation-lookup suite. The two fields are deliberately a matched
// pair, differing in ONE property, so a test that passes for a reason other than the relation
// fails on its sibling:
//
//   "Related Code"  -- declares TableRelation, declares NO OnLookup.
//   "Plain Code"    -- declares NEITHER. Same type, same length, same absence of a trigger.
//
// Neither field declares OnLookup, and neither of their controls on "TRL Card" does either.
// So a lookup on "Related Code" has exactly one thing to go on -- the TableRelation -- and a
// lookup on "Plain Code" has nothing at all. That is what makes the negative test a real
// boundary rather than a restatement: an implementation that opened some page regardless of
// whether a relation exists passes the positive test and fails the negative one.

table 60565 "TRL Host"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        // Lookup comes from the TableRelation, and from nothing else.
        field(2; "Related Code"; Code[20])
        {
            TableRelation = "TRL Related"."Code";
        }
        // The control: no relation, no trigger, nothing to resolve a lookup from.
        field(3; "Plain Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
