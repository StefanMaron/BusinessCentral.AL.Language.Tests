// @expect AL0190 | Constant value '250000T' is outside the range for a Time
// A time literal with 25 hours.
codeunit 59594 "MNC P 0594"
{
    procedure Run1()
    var
        T: Time;
    begin
        T := 250000T;
    end;
}
