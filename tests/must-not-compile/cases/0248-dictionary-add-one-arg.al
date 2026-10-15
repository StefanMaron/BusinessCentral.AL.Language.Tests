// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Value' of 'Add(Text, Integer)'
// Dictionary.Add is called with one argument.
codeunit 50054 "MNC C248"
{
    procedure Run1()
    var
        D: Dictionary of [Text, Integer];
    begin
        D.Add('k');
    end;
}
