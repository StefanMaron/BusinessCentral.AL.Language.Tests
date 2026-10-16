// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Guid.ToText with and without delimiters, CreateGuid shape
// BC versions: 29 (27 and 28 by CI)

codeunit 70322 "LT P93 Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(T: Text): Text
    var
        R: Text;
        i: Integer;
    begin
        R := 'len=' + Format(StrLen(T));
        R += ' first=' + CopyStr(T, 1, 1);
        R += ' last=' + CopyStr(T, StrLen(T), 1);
        for i := 1 to StrLen(T) do
            if not (T[i] in ['0' .. '9', 'a' .. 'f', 'A' .. 'F']) then
                R += ' [' + Format(i) + ']=' + CopyStr(T, i, 1);
        exit(R);
    end;

    [Test]
    procedure ToText_FixedGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Evaluate(G, '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Observe('tt', G.ToText());
        Observer.Observe('tt-true', G.ToText(true));
        Observer.Observe('tt-false', G.ToText(false));
        Observer.Observe('format', Format(G));
        Observer.Observe('format-0', Format(G, 0, 0));
        Observer.Observe('format-1', Format(G, 0, 1));
        Observer.Observe('format-2', Format(G, 0, 2));
        Observer.Observe('format-3', Format(G, 0, 3));
        Observer.Observe('format-9', Format(G, 0, 9));
        Observer.Observe('format-4', Format(G, 0, 4));
        Observer.Observe('lowercase-in', Format(Lowercase(G.ToText())));
        Observer.Finish();
    end;

    [Test]
    procedure ToText_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Observer.Observe('tt', G.ToText());
        Observer.Observe('tt-true', G.ToText(true));
        Observer.Observe('tt-false', G.ToText(false));
        Observer.Observe('format', Format(G));
        Observer.Observe('format-9', Format(G, 0, 9));
        Observer.Observe('isnull', Format(IsNullGuid(G)));
        Observer.Finish();
    end;

    [Test]
    procedure ToText_ParseForms()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
    begin
        Evaluate(G, 'e6c0bda3-5b0a-4a7e-9a5e-0123456789ab');
        Observer.Observe('lower-no-braces', G.ToText());
        Evaluate(G2, '{E6C0BDA3-5B0A-4A7E-9A5E-0123456789AB}');
        Observer.Observe('equal', Format(G = G2));
        Observer.Observe('tt-equal', Format(G.ToText() = G2.ToText()));
        Observer.Observe('tt-false-eq-true', Format(G.ToText(false) = G.ToText(true)));
        Observer.Observe('tt-false-eq-tt', Format(G.ToText(false) = G.ToText()));
        Observer.Observe('tt-true-eq-tt', Format(G.ToText(true) = G.ToText()));
        Observer.Observe('rt', Format(Evaluate(G2, G.ToText(false))));
        Observer.Observe('rt-eq', Format(G2 = G));
        Observer.Observe('rt-true', Format(Evaluate(G2, G.ToText(true))));
        Observer.Finish();
    end;

    [Test]
    procedure CreateGuid_Shape()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        H: Guid;
    begin
        G := CreateGuid();
        H := CreateGuid();
        Observer.Observe('notnull', Format(not IsNullGuid(G)));
        Observer.Observe('distinct', Format(G <> H));
        Observer.Observe('tt-shape', Shape(G.ToText()));
        Observer.Observe('tt-true-shape', Shape(G.ToText(true)));
        Observer.Observe('tt-false-shape', Shape(G.ToText(false)));
        Observer.Observe('format-shape', Shape(Format(G)));
        Observer.Observe('format-9-shape', Shape(Format(G, 0, 9)));
        Observer.Observe('format-eq-tt', Format(Format(G) = G.ToText()));
        Observer.Observe('format-9-eq-tt-true', Format(Format(G, 0, 9) = G.ToText(true)));
        Observer.Observe('tt-two-differ', Format(G.ToText() <> H.ToText()));
        Observer.Finish();
    end;
}
