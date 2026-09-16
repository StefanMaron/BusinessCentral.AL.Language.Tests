// The positive twin of "ALT No Subscriber Table" (60590): identical shape, but
// "ALT Subscribed Table Sub" (60591) subscribes to its OnAfterInsertEvent.
//
// The pair exists so one test run can measure both arms against the SAME write sequence.
// A single table cannot distinguish "subscribers fired" from "every table fires", which is
// the distinction "Test No Subscriber Events" (60592) is about.
table 60593 "ALT Subscribed Table"
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
