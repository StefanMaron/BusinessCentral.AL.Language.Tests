// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'Text'
// An Integer variable is passed as the key of IsolatedStorage.Set, whose Key parameter is a Text.
codeunit 59900 "MNC IsoKey Int 0480"
{
    procedure Run1()
    var
        I: Integer;
    begin
        IsolatedStorage.Set(I, 'value');
    end;
}
