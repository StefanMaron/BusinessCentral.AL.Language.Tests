// @expect AL0296 | The application object or method 'User Property' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A permission set in a Cloud app names the table object (not its data) of a system table with Scope = OnPrem (corpus issue 669, writer CO).
permissionset 50000 "MNC CO 1713"
{
    Assignable = true;
    Permissions = table "User Property" = X;
}
