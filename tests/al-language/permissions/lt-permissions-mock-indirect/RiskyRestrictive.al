// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY: codeunit TestPermissions = Restrictive (what a test observes with the platform's restrictive test permissions).

table 70468 "LT P116 Rs Open"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 70469 "LT P116 Restrictive"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    [Test]
    procedure P116_InsertUnderRestrictive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P116 Rs Open";
    begin
        Row.DeleteAll();
        Observer.Observe('deleteall', 'no error');
        Row."Entry No." := 1;
        asserterror Row.Insert();
        Observer.ObserveError('insert');
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('count', 'no error');
        Observer.Expect('deleteall', 'no error');
        Observer.Expect('insert|text', 'Sorry, the current permissions prevented the action. (TableData 70468 LT P116 Rs Open Insert: AL Language Coverage Tests)');
        Observer.Expect('insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('count', '0');
        Observer.Expect('count', 'no error');
        Observer.Verify();
    end;
}

codeunit 70470 "LT P116 NonRestrictive"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    [Test]
    procedure P116_InsertUnderNonRestrictive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P116 Rs Open";
    begin
        Row.DeleteAll();
        Observer.Observe('deleteall', 'no error');
        Row."Entry No." := 1;
        asserterror Row.Insert();
        Observer.ObserveError('insert');
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('count', 'no error');
        Observer.Expect('deleteall', 'no error');
        Observer.Expect('insert|text', 'Sorry, the current permissions prevented the action. (TableData 70468 LT P116 Rs Open Insert: AL Language Coverage Tests)');
        Observer.Expect('insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('count', '0');
        Observer.Expect('count', 'no error');
        Observer.Verify();
    end;
}
