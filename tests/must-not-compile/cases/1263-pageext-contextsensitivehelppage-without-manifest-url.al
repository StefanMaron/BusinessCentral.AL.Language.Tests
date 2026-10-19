// @expect AL0543 | The manifest property 'contextSensitiveHelpUrl' must be set in order to use the property 'ContextSensitiveHelpPage'.
// ContextSensitiveHelpPage on a page extension needs the manifest property contextSensitiveHelpUrl (the page and request page forms are
// cases 0841 and 0812). With contextSensitiveHelpUrl in app.json a page, a page extension and a request page compile (checked locally; the
// corpus apps do not set it, so no runtime test exists).
table 50000 "MNC BB Row"
{
    fields { field(1; Id; Integer) { } field(2; Lvl; Integer) { } field(3; Txt; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50001 "MNC BB Page"
{
    PageType = List;
    SourceTable = "MNC BB Row";
    layout
    {
        area(Content)
        {
            group(G)
            {
                
                field(Id; Rec.Id) { }
                field(Txt; Rec.Txt) { }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            fileuploadaction(Upload1)
            {
                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
        }
    }
}
pageextension 50002 "MNC BB Ext" extends "MNC BB Page"
{
    ContextSensitiveHelpPage = 'my-ext';
}
