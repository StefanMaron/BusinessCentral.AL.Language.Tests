// @expect AL0191 | Constant value '150126D' is outside the range for a Date.
// A date literal in the day-month-year order (the only form is yyyymmddD).
codeunit 59581 "MNC P 0581"
{
    procedure Run1()
    var
        D: Date;
    begin
        D := 150126D;
    end;
}
