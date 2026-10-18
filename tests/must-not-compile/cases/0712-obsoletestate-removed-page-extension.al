// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// Removed is not a value of ObsoleteState for a page extension, or for a group, field or action it adds.
table 59712 "MNC U 712" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 59713 "MNC U Page 712" { PageType = Card; SourceTable = "MNC U 712"; layout { area(Content) { field(F0; Rec.Id) { } } } actions { area(Processing) { } } }
pageextension 59714 "MNC U Ext 712" extends "MNC U Page 712"
{
    ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0';
    layout { addlast(Content) {
        group(G2) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; field(F4; Rec.Id) { } }
        field(F5; Rec.Id) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
    } }
    actions { addlast(Processing) { action(A2) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } } }
}
