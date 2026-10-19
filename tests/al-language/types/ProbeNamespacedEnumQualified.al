namespace Probe.NsTest.Qualified;

codeunit 69459 "Probe Ns Enum Qualified"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QualifiedForms_FromIntegerNamesAndMembers()
    var
        K: Enum Probe.NsEnum.Sub."Probe Ns Kind";
        Observer: Codeunit "Probe Observer";
    begin
        K := Enum::Probe.NsEnum.Sub."Probe Ns Kind".FromInteger(3);
        Observer.Observe('fromInteger', Format(K));
        Observer.Observe('names', Format(K.Names().Count()) + ':' + K.Names().Get(2));
        Observer.Observe('ordinals', Format(K.Ordinals().Get(2)));
        K := Probe.NsEnum.Sub."Probe Ns Kind"::Zero;
        Observer.Observe('memberViaNamespaceQualifiedType', Format(K, 0, 2));
        K := Enum::Probe.NsEnum.Sub."Probe Ns Kind"::Three;
        Observer.Observe('memberViaEnumKeyword', Format(K, 0, 2));
        Observer.Observe('databaseTableId', Format(Database::Probe.NsEnum.Sub."Probe Ns Row"));
        Observer.Expect('fromInteger', 'Three Cap');
        Observer.Expect('names', '2:Three');
        Observer.Expect('ordinals', '3');
        Observer.Expect('memberViaNamespaceQualifiedType', '0');
        Observer.Expect('memberViaEnumKeyword', '3');
        Observer.Expect('databaseTableId', '69458');
        Observer.Verify();
    end;

    [Test]
    procedure QualifiedForms_EnumKeywordNamesCall()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
    begin
        Names := Enum::Probe.NsEnum.Sub."Probe Ns Kind".Names();
        Observer.Observe('names', Format(Names.Count()));
        Observer.Observe('ordinalOfThree', Format(Enum::Probe.NsEnum.Sub."Probe Ns Kind".FromInteger(3), 0, 2));
        Observer.Expect('names', '2');
        Observer.Expect('ordinalOfThree', '3');
        Observer.Verify();
    end;
}
