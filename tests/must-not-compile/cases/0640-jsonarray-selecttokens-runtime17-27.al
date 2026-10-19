// @expect AL0666 | 'SelectTokens' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @until 27
// JsonArray.SelectTokens needs runtime 17; the BC 27 app runs on 16.1 (28 and 29: runtime 17.1 and 18.0, the file compiles; JsonObject.SelectTokens is case 0364).
codeunit 50640 "MNC JsonArray SelectTokens"
{
    procedure Run1()
    var
        A: JsonArray;
        L: List of [JsonToken];
        B: Boolean;
    begin
        B := A.SelectTokens('$[0]', L);
    end;
}
