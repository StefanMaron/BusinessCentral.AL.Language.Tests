// Fixture for TestFieldObsoleteStateVirtualTable.al — three fields covering the three
// ObsoleteState values a plain (non-strict) app can declare directly: the undeclared
// default (No), Pending, and Removed. Declaring a field ObsoleteState = Removed from
// scratch (no prior non-removed version to diff against) compiles cleanly; BC does not
// require the removal to be observed across versions, only that the field is never
// referenced from AL code once declared Removed/Pending is fine to reference.

table 60984 "ALT ObsoleteState Fixture"
{
    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Live Field"; Text[30]) { }
        field(3; "Pending Field"; Text[30])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'pending in fixture';
        }
        field(4; "Removed Field"; Text[30])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'removed in fixture';
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
