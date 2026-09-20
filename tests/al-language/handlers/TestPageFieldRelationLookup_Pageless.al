// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Pageless (60570), TRL Pageless List (60571), TRL Host (60565)
//
// The third related table in the TableRelation-lookup suite, and the only one that declares
// NEITHER LookupPageId NOR DrillDownPageId. It is "TRL Related" (60563) minus exactly those
// properties, so a lookup that resolves a relation to it has a related table and no page the
// relation can name.
//
// BC's own NavRecord.GetPageToOpen returns LookupFormId, falling back to DrillDownPageId, and
// answers 0 for this table. What the lookup does with that 0 was the question this fixture was
// built to ask, and a service tier answered it: BC opens a modal page anyway (run 35493508143,
// on 27.0, 27.3 and 27.5). "TRL Pageless List" (60571) exists so the suite can ask WHICH page --
// it is a page over this table that this table does not name.

table 60570 "TRL Pageless"
{
    DataClassification = CustomerContent;
    // Deliberately no LookupPageId and no DrillDownPageId. That absence is the subject.

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
