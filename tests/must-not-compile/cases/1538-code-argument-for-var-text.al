// @expect AL0133 | Argument 1: cannot convert from 'Code[20]' to 'var Text'
// A Code[20] variable passed to a var Text parameter (corpus issue 672, item 45).
codeunit 51538 "MNC BU 1538"
{
    procedure Run1()
    var
        C20: Code[20];
    begin
        MaxOf(C20);
    end;

    procedure MaxOf(var s: Text): Integer
    begin
        exit(MaxStrLen(s));
    end;
}
