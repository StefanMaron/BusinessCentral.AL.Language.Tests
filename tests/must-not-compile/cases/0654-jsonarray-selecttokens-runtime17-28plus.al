// @expect AL0666 | 'SelectTokens' is not available in runtime version '16.0'. The supported runtime versions are: '17.0' or greater.
// @from 28
// JsonArray.SelectTokens needs a later runtime than 16 (on 28 and 29; on 27 the method does not exist, case 0640; JsonObject.SelectTokens is case 0364).
codeunit 50654 "MNC JsonArray SelectTokens"
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
