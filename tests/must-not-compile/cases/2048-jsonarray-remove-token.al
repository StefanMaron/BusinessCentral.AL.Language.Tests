// @expect AL0132 | 'JsonArray' does not contain a definition for 'Remove'
// Writer QV (AL Runner issue 5680, neighbor of JsonObject.Remove): JsonArray has no Remove(JsonToken) method; RemoveAt(Index) removes by
// position (json/JsonArrayBasics.al, RemoveAtAndRemove).
codeunit 52048 "MNC QV C2048"
{
    procedure Run1()
    var
        J: JsonArray;
        T: JsonToken;
    begin
        J.Add(1);
        J.Get(0, T);
        J.Remove(T);
    end;
}
