// @expect AL0122 | Cannot implicitly convert type 'Date' to 'DateTime'. Use an explicit conversion or change the type.
// A Date does not assign to a DateTime variable (issue 649 item 16; CreateDateTime(D, T) is the way). A Variant holding a Date assigned to a
// DateTime at run time is in tests/al-language/types/lt-ax-text-format-dates/AxDurationDateTime.al.
codeunit 51193 "MNC AX Date To DateTime"
{
    procedure Probe(): DateTime
    var
        D: Date;
        DT: DateTime;
    begin
        D := DMY2Date(15, 3, 2024);
        DT := D;
        exit(DT);
    end;
}
