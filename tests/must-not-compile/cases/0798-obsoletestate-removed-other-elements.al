// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// Removed is not a value of ObsoleteState for a table field group, page customization, permission set, profile, query column, query filter,
// report data item and request page (8 elements, one AL0169 each).
table 59990 "MNC X Src" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } fieldgroups { fieldgroup(DropDown; Id) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } } }
page 59991 "MNC X Page" { PageType = Card; SourceTable = "MNC X Src"; layout { area(Content) { field(F; Rec.Id) { } } } }
pagecustomization "MNC X Cust" customizes "MNC X Page" { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; layout { modify(F) { Visible = false; } } }
permissionset 59992 "MNC X PS" { Assignable = true; ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; Permissions = tabledata "MNC X Src" = R; }
page 59993 "MNC X RC" { PageType = RoleCenter; }
profile "MNC X Prof" { Caption = 'x'; RoleCenter = "MNC X RC"; ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
query 59994 "MNC X Q" { elements { dataitem(S; "MNC X Src") { column(Id; Id) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } filter(Flt; Id) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } } } }
report 59995 "MNC X Rep"
{
    ProcessingOnly = true;
    dataset { dataitem(S; "MNC X Src") { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } }
    requestpage { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; layout { area(Content) { field(Z; Zz) { } } } }
    var Zz: Integer;
}
