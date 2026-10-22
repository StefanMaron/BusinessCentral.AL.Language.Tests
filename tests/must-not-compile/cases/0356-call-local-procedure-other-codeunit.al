// @expect AL0161 | 'Secret()' is inaccessible due to its protection level
// A local procedure of another codeunit is called.
codeunit 50174 "MNC C356"
{
    local procedure Secret()
    begin
    end;
}

codeunit 50175 "MNC D356"
{
    procedure Run1()
    var
        C: Codeunit "MNC C356";
    begin
        C.Secret();
    end;
}
