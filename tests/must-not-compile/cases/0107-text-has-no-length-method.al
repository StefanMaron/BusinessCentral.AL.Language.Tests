// @expect AL0132 | 'Text' does not contain a definition for 'Length'
// Text has no Length method (StrLen is the function).
codeunit 50111 "MNC Text Length"
{
    procedure Describe(): Integer
    var
        Value: Text;
    begin
        exit(Value.Length());
    end;
}
