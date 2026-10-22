// @expect AL0408 | The type 'Variant' cannot be used as a type argument in this context.
// @expect AL0408 | The type 'Variant' cannot be used as a type argument in this context.
// Corpus issue 670 item 3 (microsoft/AL#913): Dictionary of [Text, Variant] and List of [Variant] are refused. A procedure that returns Variant compiles.
codeunit 50747 "MNC C1747"
{
    procedure Run1()
    var
        D: Dictionary of [Text, Variant];
    begin
    end;

    procedure Run2()
    var
        L: List of [Variant];
    begin
    end;

    procedure ReturnsVariant(): Variant
    begin
    end;
}
