// @expect AL0133 | Argument 2: cannot convert from 'Text' to 'Integer'
// A Text value is added to a Dictionary of Text to Integer.
codeunit 50055 "MNC C249"
{
    procedure Run1()
    var
        D: Dictionary of [Text, Integer];
    begin
        D.Add('k', 'v');
    end;
}
