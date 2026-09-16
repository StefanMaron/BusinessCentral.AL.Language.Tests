// A permission set of its own for the two "Test No Subscriber Events" (60592) tables.
//
// Deliberately NOT added to ALTPermissionSet (60022): "Test Perm. Set Grants" (60604)
// asserts that set declares EXACTLY 17 tabledata grants, so extending it silently breaks a
// passing test that has nothing to do with events.
permissionset 60594 ALTNoSubscriberPermSet
{
    Assignable = true;
    Permissions =
        tabledata "ALT No Subscriber Table" = RIMD,
        tabledata "ALT Subscribed Table" = RIMD;
}
