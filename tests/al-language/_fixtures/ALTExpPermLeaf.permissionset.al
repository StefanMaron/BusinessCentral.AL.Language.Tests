// The INCLUDED half of a two-set pair for "Test Metadata Expanded Perm" (67945).
//
// "Metadata Permission" (2000000251) lists what a set DECLARES; "Expanded Permission"
// (2000000254) lists what it grants once its IncludedPermissionSets are expanded. A set
// that includes another is the only shape where the two tables disagree, so this leaf
// grants exactly one thing the composite below does not declare itself.
//
// Assignable = false on purpose: both tables list non-assignable sets, and that is pinned
// by the suite. Nothing else in the corpus depends on this set.
permissionset 67945 "ALT ExpPerm Leaf"
{
    Assignable = false;
    Permissions =
        tabledata "ALT Keyed" = R;
}
