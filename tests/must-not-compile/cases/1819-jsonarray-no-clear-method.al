// @expect AL0132 | 'JsonArray' does not contain a definition for 'Clear'
// Corpus issue 671 item 40 (microsoft/AL#1440): JsonArray has no Clear method; Clear(variable) empties it (json/lt-db-json-leads/DbJsonLeads.al).
codeunit 51819 "MNC DB C1819"
{
    procedure Run1()
    var
        J: JsonArray;
    begin
        J.Clear();
    end;
}
