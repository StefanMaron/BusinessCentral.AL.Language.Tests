// @expect AL0132 | 'JsonToken' does not contain a definition for 'GetName'
// JsonToken has no GetName method.
codeunit 50041 "MNC C235"
{
    procedure Run1()
    var
        J: JsonToken;
        T: Text;
    begin
        T := J.GetName();
    end;
}
