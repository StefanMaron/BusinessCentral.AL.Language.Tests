// @expect AL0132 | 'JsonObject' does not contain a definition for 'RemoveAll'
// Corpus issue 671 item 40 (microsoft/AL#1440): JsonObject has no RemoveAll method; Clear(variable) empties it (json/lt-db-json-leads/DbJsonLeads.al).
codeunit 51816 "MNC DB C1816"
{
    procedure Run1()
    var
        J: JsonObject;
    begin
        J.RemoveAll();
    end;
}
