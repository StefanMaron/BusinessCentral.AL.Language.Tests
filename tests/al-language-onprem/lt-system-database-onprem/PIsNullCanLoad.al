// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-isnull-method
// Scope: in-scope (OnPrem app only: System.IsNull, System.CanLoadType (DotNet))
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61235
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: dotnet declaration of System.String (mscorlib) with alias LTP109Str1; if DotNet declarations fail to compile the file is dropped
//
// IsNull of a never assigned DotNet variable and of an assigned one; CanLoadType of an assigned one and of a never assigned one.
// BC versions: 29 (27 and 28 by CI)
dotnet
{
    assembly("mscorlib")
    {
        type("System.String"; "LTP109Str1") { }
    }
}

codeunit 61235 "LT P109 IsNull CanLoad"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCanLoad(var Str: DotNet LTP109Str1; var Result: Boolean)
    begin
        Result := CanLoadType(Str);
    end;

    [Test]
    procedure P109_IsNull_Unassigned()
    var
        Observer: Codeunit "Probe Observer";
        Str: DotNet LTP109Str1;
    begin
        Observer.Observe('unassigned', Format(IsNull(Str)));
        Observer.Expect('unassigned', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P109_IsNull_Assigned()
    var
        Observer: Codeunit "Probe Observer";
        Str: DotNet LTP109Str1;
    begin
        Str := Str.Copy('abc');
        Observer.Observe('assigned', Format(IsNull(Str)));
        Observer.Observe('assigned_length', Format(Str.Length));
        Clear(Str);
        Observer.Observe('after_clear', Format(IsNull(Str)));
        Observer.Expect('assigned', 'No');
        Observer.Expect('assigned_length', '3');
        Observer.Expect('after_clear', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P109_CanLoadType()
    var
        Observer: Codeunit "Probe Observer";
        Str: DotNet LTP109Str1;
        Result: Boolean;
    begin
        Str := Str.Copy('abc');
        Observer.Observe('assigned_call', Format(TryCanLoad(Str, Result)));
        Observer.Observe('assigned_result', Format(Result));
        Observer.Observe('assigned_direct', Format(CanLoadType(Str)));
        Clear(Str);
        Result := false;
        Observer.Observe('unassigned_call', Format(TryCanLoad(Str, Result)));
        Observer.Observe('unassigned_result', Format(Result));
        Observer.Observe('unassigned_error', GetLastErrorText());
        Observer.Expect('assigned_call', 'Yes');
        Observer.Expect('assigned_result', 'Yes');
        Observer.Expect('assigned_direct', 'Yes');
        Observer.Expect('unassigned_call', 'Yes');
        Observer.Expect('unassigned_result', 'Yes');
        Observer.Expect('unassigned_error', '');
        Observer.Verify();
    end;
}
