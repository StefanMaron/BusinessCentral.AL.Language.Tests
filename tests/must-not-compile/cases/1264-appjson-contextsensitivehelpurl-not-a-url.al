// @expect AL1150 | The link in parameter 'contextSensitiveHelpUrl' (not a url) is not valid. The URL must start with either 'http://' or 'https://'
// @appjson {"contextSensitiveHelpUrl": "not a url"}
// A page sets ContextSensitiveHelpPage and app.json has a contextSensitiveHelpUrl that is no URL: only the manifest is refused (AL1150).
table 50000 "MNC BB Row"
{
    fields { field(1; Id; Integer) { } field(2; Lvl; Integer) { } field(3; Txt; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50001 "MNC BB Page"
{
    PageType = List;
    SourceTable = "MNC BB Row";
    ContextSensitiveHelpPage = 'my-page';
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
