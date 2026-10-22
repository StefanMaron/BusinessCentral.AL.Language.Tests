// @expect AL0774 | Try methods should not specify an explicit return value, because the value will be discarded. The actual return value depends on whether the method returns an error or not.
// @expect AL0774 | Try methods should not specify an explicit return value, because the value will be discarded. The actual return value depends on whether the method returns an error or not.
// A [TryFunction] without a declared return value that calls exit(false) or exit(true) (corpus #670 item 31). A bare exit; compiles.
codeunit 50000 "MNC CU Try Exit"
{
    [TryFunction]
    procedure TryExitFalse()
    begin
        exit(false);
    end;

    [TryFunction]
    procedure TryExitTrue()
    begin
        exit(true);
    end;

    [TryFunction]
    procedure TryBareExit()
    begin
        exit;
    end;
}
