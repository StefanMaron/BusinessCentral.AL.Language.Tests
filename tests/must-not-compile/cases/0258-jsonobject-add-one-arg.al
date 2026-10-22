// @expect AL0126 | No overload for method 'Add' takes 1 arguments. Candidates: built-in method 'Add(Text, JsonToken)', built-in method 'Add(Text, JsonObject)', built-in method 'Add(Text, JsonValue)', built-in method 'Add(Text, JsonArray)', built-in method 'Add(Text, Boolean)', built-in method 'Add(Text, Char)', built-in method 'Add(Text, Byte)', built-in method 'Add(Text, Option)', built-in method 'Add(Text, Integer)', built-in method 'Add(Text, BigInteger)', built-in method 'Add(Text, Decimal)', built-in method 'Add(Text, Duration)', built-in method 'Add(Text, Text)', built-in method 'Add(Text, Date)', built-in method 'Add(Text, Time)', built-in method 'Add(Text, DateTime)'
// JsonObject.Add is called with one argument.
codeunit 50066 "MNC C258"
{
    procedure Run1()
    var
        J: JsonObject;
    begin
        J.Add('a');
    end;
}
