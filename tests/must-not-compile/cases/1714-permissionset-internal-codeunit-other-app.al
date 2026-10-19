// @expect AL0161 | 'Codeunit System.Agents."Agent Impl."' is inaccessible due to its protection level
// A permission set names a codeunit that is Access = Internal in another app (System Application) (corpus issue 669, writer CO).
// No second app of our own is needed: the internal object comes from a dependency.
permissionset 50000 "MNC CO 1714"
{
    Assignable = true;
    Permissions = codeunit "Agent Impl." = X;
}
