// @expect AL0296 | The application object or method 'User Property' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A permission set in a Cloud app names tabledata of a system table with Scope = OnPrem (corpus issue 669, writer CO).
// A wildcard 'page * = X' compiles: tests/al-language/permissions/lt-co-permission-leads/CoPermissionLeads.al.
permissionset 50000 "MNC CO 1712"
{
    Assignable = true;
    Permissions = tabledata "User Property" = R;
}
