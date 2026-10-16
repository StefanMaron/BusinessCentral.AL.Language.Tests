// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73999
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on a codeunit variable: state restarts; SingleInstance codeunit keeps state
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 73997 "LT P95 State 73997"
{
    var
        Counter: Integer;
        Name: Text;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure SetName(N: Text)
    begin
        Name := N;
    end;

    procedure GetName(): Text
    begin
        exit(Name);
    end;
}

codeunit 73998 "LT P95 Single 73998"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;
}

codeunit 73999 "LT P95 Clear Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearCodeunitVar()
    var
        Observer: Codeunit "Probe Observer";
        St: Codeunit "LT P95 State 73997";
        Sg: Codeunit "LT P95 Single 73998";
        Sg2: Codeunit "LT P95 Single 73998";
    begin
        St.Bump();
        St.Bump();
        St.SetName('x');
        Observer.Observe('before', Format(St.Bump()) + '|' + St.GetName());
        Clear(St);
        Observer.Observe('after_clear', Format(St.Bump()) + '|[' + St.GetName() + ']');
        Clear(St);
        Clear(St);
        Observer.Observe('clear_twice', Format(St.Bump()));
        Sg.Bump();
        Sg.Bump();
        Observer.Observe('single_before', Format(Sg.Bump()));
        Clear(Sg);
        Observer.Observe('single_after_clear', Format(Sg.Bump()));
        Sg2.Bump();
        Observer.Observe('single_second_var_shares', Format(Sg2.Bump()));
        Clear(Sg2);
        Observer.Observe('single_after_second_clear', Format(Sg.Bump()));

        Observer.Finish();
    end;

}
