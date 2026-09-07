// The other half of the <SourceObject> property set Page Metadata (2000000138) exposes:
// AutoSplitKey (23), DelayedInsert (19) and MultipleNewLines (21), plus a SourceTableView
// (15) declaring ONLY a where(...) and no sorting(...).
//
// Split from "ALT Source Object Props Page" rather than piled onto it because these three
// only make sense on an editable line page, while the five over there are declared on a
// read-only list — and because a page that declares BOTH halves cannot show that the two
// groups are read independently.
//
// The view declares no sorting on purpose. Page Metadata renders column 15 as BC's own
// formatted string, whose SORTING / ORDER / WHERE segments are each conditional, so a page
// with a where and no sorting pins the WHERE segment on its own. Status is field 6 of
// "ALT Keyed" and "ALT Status"::Active is ordinal 2, so the column is expected to name the
// field by NUMBER and the enum member by ORDINAL — the two representations a caller reading
// the AL source would not have.
page 60995 "ALT Source Object Flags Page"
{
    Caption = 'ALT Source Object Flags Page';
    PageType = List;
    SourceTable = "ALT Keyed";
    SourceTableView = where(Status = const(Active));

    AutoSplitKey = true;
    DelayedInsert = true;
    MultipleNewLines = true;

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
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
