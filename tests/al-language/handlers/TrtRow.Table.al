// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtSrc.al).
// Fixture table backing the "TRT Card" family of pages used by TestPage record-trigger tests.
table 60839 "TRT Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        // Deliberately ordered so the DEFAULT (0) is the wrong answer. A page that seeds this
        // in OnNewRecord and a runner that skips the trigger differ visibly; if Tenant were 0
        // the bug would be invisible.
        field(2; Kind; Option) { OptionMembers = Extension,Tenant; }
        field(3; Note; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
