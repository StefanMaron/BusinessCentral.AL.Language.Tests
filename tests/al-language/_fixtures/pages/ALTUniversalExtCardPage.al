// A card page over the BASE table "ALT Universal" (60000) with a field control bound
// to "Ext Validated" (60250), a field added by tableextension "ALT Universal Validated
// Ext" (60025, ALTUniversalValidated.TableExt.al) — not a field the page's own table
// declares. Exists so a TestPage driven over this page exercises reading and writing an
// EXTENSION field's control, distinct from every other ALT card/list page fixture, which
// only bind controls to the base table's own fields.
page 60018 "ALT Universal Ext Card Page"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    Caption = 'ALT Universal Ext Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Ext Validated"; Rec."Ext Validated")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
