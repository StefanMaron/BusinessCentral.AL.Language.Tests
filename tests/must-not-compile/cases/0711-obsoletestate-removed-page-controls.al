// @expect AL0169 | The option value 'Removed' is not valid
// @expect AL0169 | The option value 'Removed' is not valid
// @expect AL0169 | The option value 'Removed' is not valid
// @expect AL0169 | The option value 'Removed' is not valid
// Removed is not a value of ObsoleteState for a page group, cue group, label, field or separator.
table 59711 "MNC U 711" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 59712 "MNC U Page 711"
{
    PageType = Card;
    SourceTable = "MNC U 711";
    layout
    {
        area(Content)
        {
            group(G1) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; field(F1; Rec.Id) { } }
            cuegroup(CG1) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; field(F2; Rec.Id) { } }
            label(L1) { Caption = 'x'; ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
        }
    }
    actions { area(Processing) { separator(S1) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } } }
}
