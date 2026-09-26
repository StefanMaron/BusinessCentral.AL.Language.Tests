// ALTSeparatorCaptionedExt: changes a field's Caption through modify(...) to a text carrying
// ';' and '"', so the modified caption must come back whole as well.
tableextension 60026 "ALT Separator Captioned Ext" extends "ALT Separator Captioned"
{
    fields
    {
        modify("Modified Field")
        {
            Caption = 'Changed; by "extension"';
        }
    }
}
