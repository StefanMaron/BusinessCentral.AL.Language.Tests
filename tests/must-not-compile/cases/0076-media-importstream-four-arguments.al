// @expect AL0126 | No overload for method 'ImportStream' takes 4 arguments. Candidates: built-in method 'ImportStream(InStream, Text, [Text])'
// Media.ImportStream with a file name as a fourth argument: BC 27 has only (InStream, Description, [MimeType]).
// @from 27
// @until 27
table 50000 "MNC Media Row"
{
    fields { field(1; Code; Code[20]) { } field(2; Pic; Media) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50001 "MNC Media"
{
    procedure Do(var InS: InStream)
    var
        Row: Record "MNC Media Row";
    begin
        Row.Pic.ImportStream(InS, 'description', 'image/png', 'picture.png');
    end;
}
