// @expect AL0161 | 'Shown' is inaccessible due to its protection level
// A global variable of another codeunit is read through a codeunit variable.
codeunit 50178 "MNC C358"
{
    var
        Shown: Integer;
}

codeunit 50179 "MNC D358"
{
    procedure Run1()
    var
        C: Codeunit "MNC C358";
        I: Integer;
    begin
        I := C.Shown;
    end;
}
