namespace ALLanguage.IsolationProbe;

// The SingleInstance observable for "Isol Probe Fixture" (61302). Reached from that one test
// codeunit only (check-singleinstance-fixture-owners.py).
codeunit 61303 "Isol Probe Single Instance"
{
    SingleInstance = true;

    procedure SetMark(NewMark: Integer)
    begin
        Mark := NewMark;
    end;

    procedure GetMark(): Integer
    begin
        exit(Mark);
    end;

    var
        Mark: Integer;
}
