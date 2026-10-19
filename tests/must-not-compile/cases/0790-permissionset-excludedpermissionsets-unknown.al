// @expect AL0185 | PermissionSet 'MNC Missing Set' is missing
// ExcludedPermissionSets names a permission set that does not exist.
permissionset 59990 "MNC X PS" { Assignable = true; ExcludedPermissionSets = "MNC Missing Set"; Permissions = tabledata Customer = R; }
