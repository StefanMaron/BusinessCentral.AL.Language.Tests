// A List over "ALT Keyed" declaring the five <SourceObject> page properties that Page
// Metadata (2000000138) exposes as columns 20/22/24/26/28 — ShowFilter, SaveValues,
// DataCaptionFields, LinksAllowed and PopulateAllFields.
//
// Each is declared as the OPPOSITE of its AL default, so a Page Metadata provider that
// answers the column's type default rather than the page's declaration reads back wrong for
// every one of them rather than accidentally right:
//
//   LinksAllowed       AL default TRUE   -> declared false
//   ShowFilter         AL default TRUE   -> declared false
//   SaveValues         AL default FALSE  -> declared true
//   PopulateAllFields  AL default FALSE  -> declared true
//   DataCaptionFields  AL default (none) -> declared "Entry No.", Name
//
// DataCaptionFields is stated here as field NAMES, which is the only spelling AL accepts.
// Page Metadata's column reports field NUMBERS, so the pair also pins that the platform —
// not the caller — does that resolution. "Entry No." is field 1 of "ALT Keyed" and Name is
// field 2, so the column is expected to read "1,2".
page 60994 "ALT Source Object Props Page"
{
    Caption = 'ALT Source Object Props Page';
    PageType = List;
    SourceTable = "ALT Keyed";
    Editable = false;

    LinksAllowed = false;
    ShowFilter = false;
    SaveValues = true;
    PopulateAllFields = true;
    DataCaptionFields = "Entry No.", Name;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
