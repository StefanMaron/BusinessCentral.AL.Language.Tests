// @expect AL0122 | Cannot implicitly convert type 'JsonToken' to 'JsonObject'. Use an explicit conversion or change the type.
// A JsonToken is assigned to a JsonObject.
codeunit 50084 "MNC C273"
{
    procedure Run1()
    var
        J: JsonObject;
        K: JsonToken;
    begin
        J := K;
    end;
}
