// The INCLUDING half of the pair described in ALTExpPermLeaf.permissionset.al.
//
// Declares one grant of its own (tabledata "ALT Universal" = RIMD) and includes
// "ALT ExpPerm Leaf", which grants tabledata "ALT Keyed" = R. So:
//   - "Metadata Permission" lists ONE row for this set (its own declaration);
//   - "Expanded Permission" lists TWO (its own plus the included set's).
// Nothing else in the corpus depends on this set.
permissionset 67946 "ALT ExpPerm Comp"
{
    Assignable = true;
    IncludedPermissionSets = "ALT ExpPerm Leaf";
    Permissions =
        tabledata "ALT Universal" = RIMD;
}
