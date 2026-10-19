// @expect AL0190 | Constant value '2359T' is outside the range for a Time
// @expect AL0190 | Constant value '1130T' is outside the range for a Time
// @expect AL0190 | Constant value '12T' is outside the range for a Time
// @expect AL0190 | Constant value '123T' is outside the range for a Time
// Corpus #664 item 27. A Time literal needs six digits (hhmmss): 2359T, 1130T, 12T and 123T are AL0190; 235900T, 235959.999T and 0T compile.
// (Case 0594 has a six-digit literal with hour 24.)
codeunit 51381 "MNC BM C1381"
{
    procedure P()
    var
        T: Time;
    begin
        T := 2359T;
        T := 1130T;
        T := 235900T;
        T := 235959.999T;
        T := 0T;
        T := 12T;
        T := 123T;
    end;
}
