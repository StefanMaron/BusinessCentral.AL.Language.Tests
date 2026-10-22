// @expect AL0666 | 'SelectTokens' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @until 27
// JsonToken.SelectTokens needs runtime 17; the BC 27 app runs on 16.1 (28 and 29: runtime 17.1 and 18.0, the file compiles and
// tests/al-language/json/lt-dc-json-leads/DcJsonLeads.al pins the result; JsonObject and JsonArray are cases 0364 and 0640).
codeunit 51824 "MNC JsonToken SelectTokens"
{
    procedure Run1()
    var
        T: JsonToken;
        L: List of [JsonToken];
        B: Boolean;
    begin
        B := T.SelectTokens('$.a', L);
    end;
}
