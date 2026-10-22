// @expect AL0133 | Argument 1: cannot convert from 'Dictionary of [Integer, Text]' to 'var Variant'
// @expect AL0133 | Argument 1: cannot convert from 'List of [Text]' to 'var Variant'
// Corpus issue 670 item 10 (microsoft/AL#7360): a Dictionary or a List cannot be passed to a var Variant parameter. V := D, D := V, L := V and
// Evaluate(D, V) compile (runtime test: collections/lt-cs-odd-leads/CsCollections.al).
codeunit 50750 "MNC C1750"
{
    procedure Run1()
    var
        D: Dictionary of [Integer, Text];
        L: List of [Text];
        V: Variant;
    begin
        V := D;
        D := V;
        L := V;
        Evaluate(D, V);
        TakesVar(D);
        TakesVar(L);
    end;

    procedure TakesVar(var V: Variant)
    begin
    end;
}
