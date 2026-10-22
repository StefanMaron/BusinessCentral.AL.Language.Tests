// @expect AL0132 | 'JsonObject' does not contain a definition for 'Put'
// JsonObject has no Put method (Add or Replace).
codeunit 50034 "MNC C228"
{
    procedure Run1()
    var
        J: JsonObject;
    begin
        J.Put('a', 1);
    end;
}
