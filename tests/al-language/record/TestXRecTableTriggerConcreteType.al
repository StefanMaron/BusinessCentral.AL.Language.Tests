// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-overview
// Scope: in-scope
// Fixtures used: xRec Probe (60525)
//
// A table whose OnInsert trigger reads xRec. The AL compiler emits the xRec
// accessor as a cast to the concrete record type, e.g.
//   xRec => (Record60525)((NavRecord)this).OldRecord
// so reading xRec forces the runtime to materialise the before-image
// (NavRecord.OldRecord) and cast it to the concrete record type. If a runtime
// builds OldRecord as a base record type, that cast throws an invalid-cast
// error — which is exactly the contract this fixture guards.

table 60525 "xRec Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Counter"; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        // Read xRec (the before-image). For an insert it is the cleared record,
        // so xRec."Counter" = 0 and Counter becomes 1 — observable proof that
        // the trigger ran AND xRec was accessible as the concrete record type.
        "Counter" := xRec."Counter" + 1;
    end;
}
