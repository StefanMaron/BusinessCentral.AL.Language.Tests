// @expect AL0591 | The property CuegroupLayout is only supported on CueGroup.
// CuegroupLayout is a cue group property: a plain group refuses it, even with its one valid value Wide. Cue group, fixed and grid forms: cases 0920 to 0946.
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
                CuegroupLayout = Wide;
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
