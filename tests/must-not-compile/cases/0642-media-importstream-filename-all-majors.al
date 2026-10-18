// @expect AL0126 | No overload for method 'ImportStream' takes 4 arguments. Candidates: built-in method 'ImportStream(InStream, Text, [Text])'
// Media.ImportStream with a file name as a fourth argument does not exist on 27, 28 and 29 (case 0076 pins 27 only).
table 50642 "MNC Media Row2"
{
    fields { field(1; Code; Code[20]) { } field(2; Pic; Media) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 50642 "MNC Media2"
{
    procedure Do(var InS: InStream)
    var
        Row: Record "MNC Media Row2";
        Id: Guid;
    begin
        Id := Row.Pic.ImportStream(InS, 'description', 'image/png', 'picture.png');
    end;
}
