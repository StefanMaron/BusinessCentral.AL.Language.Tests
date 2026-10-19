namespace Probe.NsTest.Using;

using Probe.NsEnum.Sub;

codeunit 69460 "Probe Ns Enum Using"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UsingForms_FromIntegerNamesAndMembers()
    var
        K: Enum "Probe Ns Kind";
        Observer: Codeunit "Probe Observer";
    begin
        K := Enum::"Probe Ns Kind".FromInteger(3);
        Observer.Observe('fromInteger', Format(K));
        Observer.Observe('names', Format(K.Names().Count()) + ':' + K.Names().Get(2));
        K := "Probe Ns Kind"::Zero;
        Observer.Observe('memberPlain', Format(K, 0, 2));
        K := Enum::"Probe Ns Kind"::Three;
        Observer.Observe('memberViaEnumKeyword', Format(K, 0, 2));
        Observer.Observe('databaseTableId', Format(Database::"Probe Ns Row"));
        Observer.Expect('fromInteger', 'Three Cap');
        Observer.Expect('names', '2:Three');
        Observer.Expect('memberPlain', '0');
        Observer.Expect('memberViaEnumKeyword', '3');
        Observer.Expect('databaseTableId', '69458');
        Observer.Verify();
    end;

    [Test]
    procedure UsingForms_EnumFieldOfNamespacedTable()
    var
        Row: Record "Probe Ns Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.Kind := Row.Kind::Three;
        Observer.Observe('fieldMember', Format(Row.Kind));
        Observer.Observe('fieldOrdinal', Format(Row.Kind, 0, 2));
        Observer.Expect('fieldMember', 'Three Cap');
        Observer.Expect('fieldOrdinal', '3');
        Observer.Verify();
    end;
}
