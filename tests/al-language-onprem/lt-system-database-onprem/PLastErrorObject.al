// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope (OnPrem app only: System.GetLastErrorObject (DotNet))
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61237
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: dotnet declarations of System.Exception and System.Type (mscorlib), aliases LTP109Exc3 and LTP109Typ3
//
// GetLastErrorObject after a caught error (the exception type and message), and with no error.
// BC versions: 29 (27 and 28 by CI)
dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; "LTP109Exc3") { }
        type("System.Type"; "LTP109Typ3") { }
    }
}

codeunit 61237 "LT P109 LastErrorObject"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRaise()
    begin
        Error('LT P109 raised');
    end;

    [Test]
    procedure P109_GetLastErrorObject_AfterError()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LTP109Exc3;
        T: DotNet LTP109Typ3;
    begin
        Observer.Observe('try_result', Format(TryRaise()));
        Exc := GetLastErrorObject();
        Observer.Observe('is_null', Format(IsNull(Exc)));
        if not IsNull(Exc) then begin
            Observer.Observe('message', Exc.Message);
            T := Exc.GetType();
            Observer.Observe('type', T.FullName);
        end;
        Observer.Expect('try_result', 'No');
        Observer.Expect('is_null', 'No');
        Observer.Expect('message', 'LT P109 raised');
        Observer.Expect('type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetLastErrorObject_AfterAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LTP109Exc3;
    begin
        ClearLastError();
        asserterror Error('LT P109 asserted');
        Exc := GetLastErrorObject();
        Observer.Observe('is_null', Format(IsNull(Exc)));
        if not IsNull(Exc) then
            Observer.Observe('message', Exc.Message);
        Observer.Expect('is_null', 'No');
        Observer.Expect('message', 'LT P109 asserted');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetLastErrorObject_AfterClear()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LTP109Exc3;
    begin
        asserterror Error('LT P109 asserted');
        ClearLastError();
        Exc := GetLastErrorObject();
        Observer.Observe('is_null_after_clear', Format(IsNull(Exc)));
        Observer.Observe('last_error_text_after_clear', GetLastErrorText());
        Observer.Expect('is_null_after_clear', 'Yes');
        Observer.Expect('last_error_text_after_clear', '');
        Observer.Verify();
    end;
}
