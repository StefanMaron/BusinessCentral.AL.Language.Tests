// @expect AL0666 | 'SelectTokens' is not available in runtime version '16.0'. The supported runtime versions are: '17.0' or greater.
// JsonObject.SelectTokens needs a later runtime than 16.
codeunit 50187 "MNC C364"
{
    procedure Run1()
    var
        J: JsonObject;
        L: List of [JsonToken];
        B: Boolean;
    begin
        B := J.SelectTokens('$.a', L);
    end;
}
