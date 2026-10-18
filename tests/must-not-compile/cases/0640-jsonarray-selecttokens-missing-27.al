// @expect AL0132 | 'JsonArray' does not contain a definition for 'SelectTokens'
// @until 27
// JsonArray.SelectTokens does not exist on 27 (28 and 29: case 0654).
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
