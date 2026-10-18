// @expect AL0126 | TODO
// MediaSet.ImportStream with a file name as a fourth argument does not exist (only InStream, Description, [MimeType]).
table 50641 "MNC MediaSet Row"
{
    fields { field(1; Code; Code[20]) { } field(2; Pics; MediaSet) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50641 "MNC MediaSet"
{
    procedure Do(var InS: InStream)
    var
        Row: Record "MNC MediaSet Row";
    begin
        Row.Pics.ImportStream(InS, 'description', 'image/png', 'picture.png');
    end;
}
