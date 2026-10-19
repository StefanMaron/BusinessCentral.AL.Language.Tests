// @expect AL0530 | The maximum length for the type 'Code' is 2048
// A Code variable may be at most Code[2048] (Code[1025] and Code[2048] compile: tests/al-language/misc/lt-cq-odd-leads/CqOddLeads.al Item43).
// Learn's Code data type page gives 1024 for variables; the compiler allows 2048 (corpus issue 672, item 43).
codeunit 51730 "MNC CQ C1730"
{
    procedure Declare()
    var
        C: Code[2049];
    begin
        C := 'a';
    end;
}
