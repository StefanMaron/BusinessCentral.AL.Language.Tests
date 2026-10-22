// Batch 7 probes: a namespaced enum named with its namespace in front, no using. Observe only.
namespace W7.Ns.Use;

codeunit 68560 "W7 Ns Qualified"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QualifiedForms()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum W7.Ns.Sub."W7 Ns Enum";
        Names: List of [Text];
        Ordinals: List of [Integer];
        Name: Text;
        Ordinal: Integer;
        NamesText: Text;
        OrdinalsText: Text;
    begin
        E := Enum::W7.Ns.Sub."W7 Ns Enum".FromInteger(1);
        Observer.Observe('Enum::Ns.Name.FromInteger(1)', Format(E));
        E := Enum::W7.Ns.Sub."W7 Ns Enum"::Gamma;
        Observer.Observe('Enum::Ns.Name::Gamma', Format(E) + ' ' + Format(E.AsInteger()));
        E := W7.Ns.Sub."W7 Ns Enum"::Alpha;
        Observer.Observe('Ns.Name::Alpha', Format(E) + ' ' + Format(E.AsInteger()));
        Names := Enum::W7.Ns.Sub."W7 Ns Enum".Names();
        foreach Name in Names do
            NamesText += Name + ',';
        Observer.Observe('Names', NamesText);
        Ordinals := Enum::W7.Ns.Sub."W7 Ns Enum".Ordinals();
        foreach Ordinal in Ordinals do
            OrdinalsText += Format(Ordinal) + ',';
        Observer.Observe('Ordinals', OrdinalsText);
        Observer.Observe('FromInteger(7)', Format(Enum::W7.Ns.Sub."W7 Ns Enum".FromInteger(7)));
        Observer.Observe('comparison', Format(E = W7.Ns.Sub."W7 Ns Enum"::Alpha));
        Observer.Expect('Enum::Ns.Name.FromInteger(1)', 'Beta Two');
        Observer.Expect('Enum::Ns.Name::Gamma', 'Gamma 7');
        Observer.Expect('Ns.Name::Alpha', 'Alpha 0');
        Observer.Expect('Names', 'Alpha,Beta Two,Gamma,');
        Observer.Expect('Ordinals', '0,1,7,');
        Observer.Expect('FromInteger(7)', 'Gamma');
        Observer.Expect('comparison', 'Yes');
        Observer.Verify();
    end;
}
