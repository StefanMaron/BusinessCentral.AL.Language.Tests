// Minimal RoleCenter page declared in the DEPENDENCY app, referenced by a profile
// declared in the AL Language Coverage Tests app -- see
// tests/al-language/profile/ALTProfileDepApp.Profile.al. This is the shape that
// actually broke AL Runner's compile pipeline (issue #2238 in
// StefanMaron/BusinessCentral.AL.Runner): resolving the profile's RoleCenter
// reference requires cross-module symbol lookup, since this page exists ONLY in
// the dependency module.
page 61002 "ALT Profile RC DepApp"
{
    PageType = RoleCenter;
    Caption = 'ALT Profile RC DepApp';

    layout
    {
        area(RoleCenter)
        {
        }
    }
}
