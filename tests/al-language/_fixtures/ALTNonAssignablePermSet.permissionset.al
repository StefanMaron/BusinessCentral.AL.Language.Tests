// A permission set that declares Assignable = false, so a test can tell the two
// permission-set tables apart: "Metadata Permission Set" (2000000250) lists every
// declared set, assignable or not, while the legacy "Permission Set" (2000000004)
// lists only the assignable ones. Nothing else in the suite depends on this set's
// contents -- it exists to be listed, and to be missing from one of the two tables.
permissionset 60023 "ALT NonAssignable"
{
    Caption = 'ALT NonAssignable Fixture';
    Assignable = false;
    Permissions =
        tabledata "ALT Universal" = R;
}
