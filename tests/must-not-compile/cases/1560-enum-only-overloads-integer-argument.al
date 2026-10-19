// @expect AL0196 | The call is ambiguous between the method 'Pick(Enum "MNC BN3 EA1560")' defined in Codeunit 'MNC BN3 C1560'
// Overloads that differ only by the enum type (microsoft/AL issue 4328, corpus #664 item 74) compile, and an argument of either enum type picks
// its own overload (misc/lt-inferred-behaviors/P69Overloads.al BN3_Overload_DifferOnlyByEnumType). An Integer argument converts to both enums,
// so the call is ambiguous.
enum 51560 "MNC BN3 EA1560"
{
    Extensible = false;
    value(0; A0) { }
    value(1; A1) { }
}

enum 51561 "MNC BN3 EB1560"
{
    Extensible = false;
    value(0; B0) { }
    value(1; B1) { }
}

codeunit 51560 "MNC BN3 C1560"
{
    local procedure Pick(A: Enum "MNC BN3 EA1560"): Text
    begin
    end;

    local procedure Pick(B: Enum "MNC BN3 EB1560"): Text
    begin
    end;

    procedure Run1()
    begin
        Pick(1);
    end;
}
