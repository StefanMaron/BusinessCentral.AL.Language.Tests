// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74008
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on a single array element leaves the others
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74008 "LT P95 Clear Array Element"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearArrayElement()
    var
        Observer: Codeunit "Probe Observer";
        Ai: array[3] of Integer;
        At: array[2] of Text;
    begin
        Ai[1] := 1; Ai[2] := 2; Ai[3] := 3;
        Clear(Ai[2]);
        Observer.Observe('elements', Format(Ai[1]) + '|' + Format(Ai[2]) + '|' + Format(Ai[3]));
        At[1] := 'a'; At[2] := 'b';
        Clear(At[1]);
        Observer.Observe('text_elements', '[' + At[1] + '][' + At[2] + ']');
        asserterror Clear(Ai[4]);
        Observer.ObserveError('out_of_range');
        asserterror Clear(Ai[0]);
        Observer.ObserveError('zero_index');

        Observer.Finish();
    end;

}
