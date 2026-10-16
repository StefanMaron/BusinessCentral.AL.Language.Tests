// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, pages 72353 and 72354, codeunit 72355
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72353 "LT P123 Api Line"
{
    PageType = API;
    APIPublisher = 'ltp123';
    APIGroup = 'probe';
    APIVersion = 'v1.0';
    EntityName = 'ltLine';
    EntitySetName = 'ltLines';
    SourceTable = "LT P123 PRow";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(lineId; Rec.Id) { Caption = 'Line Id'; }
                field(name; Rec.Name) { Caption = 'Name'; }
            }
        }
    }
}

page 72354 "LT P123 Api Header"
{
    PageType = API;
    APIPublisher = 'ltp123';
    APIGroup = 'probe';
    APIVersion = 'v1.0';
    EntityName = 'ltHeader';
    EntitySetName = 'ltHeaders';
    SourceTable = "LT P123 PRow";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { Caption = 'Id'; Editable = false; }
                field(headerId; Rec.Id) { Caption = 'Header Id'; }
                part(lines; "LT P123 Api Line")
                {
                    EntityName = 'ltLine';
                    EntitySetName = 'ltLines';
                    SubPageLink = Id = field(Id);
                }
            }
        }
    }
}

codeunit 72355 "LT P123 Api Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
}
