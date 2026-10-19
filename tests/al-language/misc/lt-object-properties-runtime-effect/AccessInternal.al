// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

interface "LT P194 IAccess"
{
    Access = Internal;

    procedure Describe(): Text;
}

codeunit 72466 "LT P194 AccImpl" implements "LT P194 IAccess"
{
    procedure Describe(): Text
    begin
        exit('impl');
    end;
}

tableextension 72465 "LT P194 Gen Acc" extends "LT P194 Gen"
{
    fields
    {
        field(72465; "Internal Fld"; Integer)
        {
            Access = Internal;
        }
    }
}

codeunit 72467 "LT P194 Access Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P194_InternalInterface_Call()
    var
        Impl: Codeunit "LT P194 AccImpl";
        Acc: Interface "LT P194 IAccess";
        Observer: Codeunit "Probe Observer";
    begin
        Acc := Impl;
        Observer.Observe('describe', Acc.Describe());
        Observer.Observe('is_interface_assigned', Format(Acc.Describe() = 'impl'));
        Observer.Expect('describe', 'impl');
        Observer.Expect('is_interface_assigned', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P194_InternalField_ReadWriteMeta()
    var
        Gen: Record "LT P194 Gen";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Gen.DeleteAll();
        Gen.Init();
        Gen."Code" := 'A1';
        Gen."Internal Fld" := 42;
        Gen.Insert();
        Gen.Get('A1');
        Observer.Observe('value', Format(Gen."Internal Fld"));
        Gen."Internal Fld" := 43;
        Gen.Modify();
        Gen.SetRange("Internal Fld", 43);
        Observer.Observe('filtered_count', Format(Gen.Count()));
        RecRef.Open(Database::"LT P194 Gen");
        FldRef := RecRef.Field(72465);
        Observer.Observe('name', FldRef.Name());
        Observer.Observe('active', Format(FldRef.Active()));
        Observer.Observe('class', Format(FldRef.Class()));
        Observer.Observe('type', Format(FldRef.Type()));
        Observer.Observe('length', Format(FldRef.Length()));
        Observer.Observe('is_enabled_in_list', Format(RecRef.FieldExist(72465)));
        Observer.Expect('value', '42');
        Observer.Expect('filtered_count', '1');
        Observer.Expect('name', 'Internal Fld');
        Observer.Expect('active', 'Yes');
        Observer.Expect('class', 'Normal');
        Observer.Expect('type', 'Integer');
        Observer.Expect('length', '4');
        Observer.Expect('is_enabled_in_list', 'Yes');
        Observer.Verify();
    end;
}
