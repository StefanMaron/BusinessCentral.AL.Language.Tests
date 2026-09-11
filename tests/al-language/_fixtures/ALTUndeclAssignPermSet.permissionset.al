// A permission set that declares NO Assignable property at all, so a test can pin what
// the platform resolves that absence to. The two existing fixtures both STATE the
// property -- "ALTPermissionSet" (60022) states true and "ALT NonAssignable" (60023)
// states false -- so nothing in the suite covered the undeclared case.
//
// This is not a hypothetical shape: three permission sets shipped in BC 28.1 declare no
// Assignable -- Base Application 208 "D365 Basic - Edit" and 209 "D365 Basic - Read",
// and System Application 68 "System Execute - Basic".
//
// The name is kept to 17 characters deliberately. "Metadata Permission Set" (2000000250)
// carries Role ID as Code[20] and TRUNCATES a longer object name into it, so a longer
// fixture name would make the tests' Role ID lookups depend on that truncation.
//
// Nothing else in the suite depends on this set's contents; it exists to be listed.
permissionset 60024 "ALT Undecl Assign"
{
    Caption = 'ALT Undecl Assign Fixture';
    Permissions =
        tabledata "ALT Universal" = R;
}
