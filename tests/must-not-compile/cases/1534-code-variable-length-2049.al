// @expect AL0530 | The maximum length for the type 'Code' is 2048
// A Code[2049] variable (corpus issue 672, item 43). Learn says a Code variable holds at most 1024 characters; the compiler
// accepts Code[1025] to Code[2048] (see tests/al-language/text/lt-text-functions/StrLen.Codeunit.al, LT_BU_StrLen_LongCodeVariables).
codeunit 51535 "MNC BU 1534"
{
    procedure Run1()
    var
        C: Code[2049];
    begin
        C := '';
    end;
}
