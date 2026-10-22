// @expect AL0160 | 'XXX' is not a valid language identifier. Use a standard language code (e.g., 'ENU', 'DEU') or LCID.
// ProfileDescriptionML with a language code that does not exist.
page 59991 "MNC X RC" { PageType = RoleCenter; }
profile "MNC X Prof" { Caption = 'x'; RoleCenter = "MNC X RC"; ProfileDescriptionML = XXX = 'a'; }
