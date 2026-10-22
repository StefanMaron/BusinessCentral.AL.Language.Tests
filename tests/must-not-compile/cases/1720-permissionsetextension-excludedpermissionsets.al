// @expect AL0124 | The property 'ExcludedPermissionSets' cannot be used in this context. Verify the property is available for the current object type.
// ExcludedPermissionSets in a permissionsetextension (corpus issue 669, item 86). Only a permissionset may exclude sets.
permissionset 50000 "MNC CP Base" { Assignable = true; Permissions = tabledata Customer = R; }
permissionset 50001 "MNC CP Neg" { Assignable = true; Permissions = tabledata Customer = R; }
permissionsetextension 50002 "MNC CP Ext" extends "MNC CP Base"
{
    ExcludedPermissionSets = "MNC CP Neg";
}
