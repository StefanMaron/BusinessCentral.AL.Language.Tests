// @expect AL0132 | 'JsonObject' does not contain a definition for 'Clear'
// Corpus issue 671 item 40 (microsoft/AL#1440): JsonObject has no Clear method; Clear(variable) empties it (json/lt-db-json-leads/DbJsonLeads.al).
codeunit 51818 "MNC DB C1818"
{
    procedure Run1()
    var
        J: JsonObject;
    begin
        J.Clear();
    end;
}
