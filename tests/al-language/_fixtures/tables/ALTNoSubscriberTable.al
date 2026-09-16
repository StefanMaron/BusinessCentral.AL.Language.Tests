// A table with NO event subscriber anywhere in this app, and no table triggers of its own.
// Used by "Test No Subscriber Events" (60592) as the negative arm: writing a row here must
// log nothing, which is what distinguishes "the platform consults the subscriber registry"
// from "the platform takes the trigger path unconditionally".
//
// Deliberately kept subscriber-free. Adding an [EventSubscriber] for this table anywhere in
// the app silently inverts that test's meaning rather than failing it.
table 60590 "ALT No Subscriber Table"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Value"; Integer)
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
