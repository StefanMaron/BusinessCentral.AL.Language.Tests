// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-visible-method
// Scope: in-scope
// Fixtures used: ALT TestPart Row (60341)
//
// A second ListPart over the same table, hosted alongside the first one but declared
// Visible = false and Enabled = false on the HOST's part control.
//
// It exists so TestPart.Visible() and TestPart.Enabled() have a discriminator. With only one
// part in play both methods would answer true and an implementation hardcoding `true` -- or
// one reading the HOST page's visibility instead of the part control's -- would pass. The
// suite asserts the two parts answer DIFFERENTLY on the same open host, which no such
// implementation can do.

page 60343 "ALT TestPart Hidden"
{
    PageType = ListPart;
    SourceTable = "ALT TestPart Row";
    Caption = 'Hidden Part Caption';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                    Caption = 'Group';
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
            }
        }
    }
}
