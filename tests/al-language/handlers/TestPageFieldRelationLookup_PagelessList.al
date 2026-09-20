// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Pageless (60570), TRL Pageless List (60571)
//
// A list page over "TRL Pageless" that the TABLE DOES NOT NAME. "TRL Pageless" declares no
// LookupPageId and no DrillDownPageId, so nothing connects this page to it except that its
// SourceTable is that table.
//
// That is the whole point of the fixture. Real BC opens SOME page for a lookup whose relation
// resolves to "TRL Pageless" -- measured, see "TRL Tests" -- and this page exists so the suite
// can ask WHICH: if a [ModalPageHandler] declared for this page runs, BC's fallback picks a
// page by source table rather than generating one, and that is a rule the runner can model.
// If the handler does not run, BC is opening something no AL object names.
//
// Deliberately minimal and deliberately NOT named by the table: adding LookupPageId here would
// answer a question the suite already answers through "TRL Related".

page 60571 "TRL Pageless List"
{
    PageType = List;
    SourceTable = "TRL Pageless";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
