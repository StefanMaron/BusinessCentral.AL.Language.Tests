// Batch 7 probes: a namespaced enum reached through a using. Observe only.
namespace W7.Ns.Other;

using W7.Ns.Sub;

codeunit 68561 "W7 Ns Using"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UsingForms()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "W7 Ns Enum";
        Names: List of [Text];
        Ordinals: List of [Integer];
        Name: Text;
        Ordinal: Integer;
        NamesText: Text;
        OrdinalsText: Text;
    begin
        E := Enum::"W7 Ns Enum".FromInteger(1);
        Observer.Observe('Enum::Name.FromInteger(1)', Format(E));
        E := Enum::"W7 Ns Enum"::Gamma;
        Observer.Observe('Enum::Name::Gamma', Format(E) + ' ' + Format(E.AsInteger()));
        E := "W7 Ns Enum"::Alpha;
        Observer.Observe('Name::Alpha', Format(E) + ' ' + Format(E.AsInteger()));
        Names := Enum::"W7 Ns Enum".Names();
        foreach Name in Names do
            NamesText += Name + ',';
        Observer.Observe('Names', NamesText);
        Ordinals := Enum::"W7 Ns Enum".Ordinals();
        foreach Ordinal in Ordinals do
            OrdinalsText += Format(Ordinal) + ',';
        Observer.Observe('Ordinals', OrdinalsText);
        Observer.Observe('FromInteger(7)', Format(Enum::"W7 Ns Enum".FromInteger(7)));
        Observer.Observe('comparison', Format(E = "W7 Ns Enum"::Alpha));
        Observer.Expect('Enum::Name.FromInteger(1)', 'Beta Two');
        Observer.Expect('Enum::Name::Gamma', 'Gamma 7');
        Observer.Expect('Name::Alpha', 'Alpha 0');
        Observer.Expect('Names', 'Alpha,Beta Two,Gamma,');
        Observer.Expect('Ordinals', '0,1,7,');
        Observer.Expect('FromInteger(7)', 'Gamma');
        Observer.Expect('comparison', 'Yes');
        Observer.Verify();
    end;
}
