// @expect AL0666 | 'SelectTokens' is not available in runtime version '16.
// Runtime of the corpus apps since the runtime move: 16.1 on BC 27 (this error), 17.1 on BC 28 and 18.0 on BC 29 (the member exists there: the file compiles, so the case holds for BC 27 only).
// @until 27
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
