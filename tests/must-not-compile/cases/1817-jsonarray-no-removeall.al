// @expect AL0132 | 'JsonArray' does not contain a definition for 'RemoveAll'
// Corpus issue 671 item 40 (microsoft/AL#1440): JsonArray has no RemoveAll method; Clear(variable) empties it (json/lt-db-json-leads/DbJsonLeads.al).
codeunit 51817 "MNC DB C1817"
{
    procedure Run1()
    var
        J: JsonArray;
    begin
        J.RemoveAll();
    end;
}
