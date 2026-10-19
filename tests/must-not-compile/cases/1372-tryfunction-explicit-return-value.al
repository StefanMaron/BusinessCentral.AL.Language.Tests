// @expect AL0774 | Try methods should not specify an explicit return value, because the value will be discarded. The actual return value depends on whether the method returns an error or not.
// @expect AL0774 | Try methods should not specify an explicit return value, because the value will be discarded. The actual return value depends on whether the method returns an error or not.
// Corpus #664 item 6. exit(false) and exit(true) in a [TryFunction] are errors (AL0774; the lead named AL0775); a bare exit is fine.
// A try function as an interface implementation is case 1384.
codeunit 51372 "MNC BM C1372"
{
    [TryFunction]
    procedure P()
    begin
        exit(false);
    end;

    [TryFunction]
    procedure Q()
    begin
        exit(true);
    end;

    [TryFunction]
    procedure R()
    begin
        exit;
    end;
}
