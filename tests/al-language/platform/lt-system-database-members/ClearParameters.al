// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74014
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on by-value and var parameters, and on a global variable from another procedure
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74014 "LT P95 Clear Parameters"
{
    Subtype = Test;
    TestPermissions = Disabled;


    var
        G: Text;

    local procedure ByValue(T: Text)
    begin
        Clear(T);
    end;

    local procedure ByVar(var T: Text)
    begin
        Clear(T);
    end;

    local procedure ListByValue(L: List of [Integer])
    begin
        Clear(L);
    end;

    local procedure ListByVar(var L: List of [Integer])
    begin
        Clear(L);
    end;

    local procedure ClearGlobal()
    begin
        Clear(G);
    end;

    local procedure ResultCleared() R: Text
    begin
        R := 'set';
        Clear(R);
        R := R + 'end';
    end;

    [Test]
    procedure ClearParameters()
    var
        Observer: Codeunit "Probe Observer";
        TextVal: Text;
        L: List of [Integer];
    begin
        TextVal := 'orig';
        ByValue(TextVal);
        Observer.Observe('byvalue_caller', TextVal);
        ByVar(TextVal);
        Observer.Observe('byvar_caller', '[' + TextVal + ']');
        L.Add(1);
        ListByValue(L);
        Observer.Observe('list_byvalue_caller', Format(L.Count()));
        L.Add(1);
        ListByVar(L);
        Observer.Observe('list_byvar_caller', Format(L.Count()));
        G := 'global';
        ClearGlobal();
        Observer.Observe('global', '[' + G + ']');
        Observer.Observe('function_result', ResultCleared());

        Observer.Finish();
    end;

}
