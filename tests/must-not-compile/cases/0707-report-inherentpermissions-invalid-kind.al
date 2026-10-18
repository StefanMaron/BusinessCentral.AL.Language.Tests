// @expect AL0195 | Invalid permission kind. Expected: 'X'
// InherentPermissions on a report takes X only.
report 59707 "MNC U Rep 707" { ProcessingOnly = true; InherentPermissions = RIMD; }
