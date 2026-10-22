// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: LT CD Row (84280) from CdObjects.al
// Facts: item 58 of corpus issue #667 (Microsoft AL issue 3737): a page whose SourceTableView is where(D = const(0D)) compiles and the app installs; which rows the page shows.
// BC versions: all (CI)

page 84299 "LT CD Const0D List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Const0D List';
    SourceTableView = where(D = const(0D));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}
