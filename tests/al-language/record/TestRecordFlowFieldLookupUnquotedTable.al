// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields
// Scope: in-scope
// Fixtures used: FFLConfigLine (60228, private to this test — co-located, no
// corpus-shared equivalent), "FFL Field Line" (60229)
// Note: regression test for a lookup() FlowField CalcFormula whose SOURCE
// TABLE NAME is an unquoted AL identifier (legal AL: quotes are only required
// when a name contains spaces). The positive case seeds
// ConfigLine.TargetTableNo with the (renumbered) ID of FFLConfigLine itself
// purely as a concrete non-default value to assert against.
// BC versions: 24+

codeunit 60230 "Test Record FF Lookup Unquot"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Positive: the FlowField must resolve to the REAL looked-up value, not just "did not
    // throw" — a stub/broken parse that always yields 0 would still let CalcFields()
    // "succeed" (no exception), so the assertion specifically checks the non-default value.
    [Test]
    procedure LookupFlowFieldWithUnquotedSourceTableResolvesRealValue()
    var
        ConfigLine: Record FFLConfigLine;
        FieldLine: Record "FFL Field Line";
    begin
        Initialize();
        ConfigLine.Init();
        ConfigLine.Validate(ReportId, 1);
        ConfigLine.Validate(LineNo, 10000);
        ConfigLine.Validate(TargetTableNo, 60228);
        ConfigLine.Insert(true);

        FieldLine.Init();
        FieldLine.Validate(ReportId, 1);
        FieldLine.Validate(ConfigLineNo, 10000);
        FieldLine.Validate(LineNo, 10000);
        FieldLine.Insert(true);

        FieldLine.CalcFields(TargetTableNo);
        Assert.AreEqual(60228, FieldLine.TargetTableNo,
            'CalcFields on a lookup() FlowField whose source table name is unquoted must resolve the real seeded value, not silently stay 0');
    end;

    // Negative control: when NO matching config line exists at all, the FlowField must
    // still (faithfully) resolve to 0 — distinguishing "genuinely no match" from the bug
    // above ("always 0 regardless of whether a match exists, because the formula never
    // parsed"). This proves the fix did not turn the lookup into an always-matches stub.
    [Test]
    procedure LookupFlowFieldWithNoMatchingConfigLineStaysZero()
    var
        FieldLine: Record "FFL Field Line";
    begin
        Initialize();
        FieldLine.Init();
        FieldLine.Validate(ReportId, 2);
        FieldLine.Validate(ConfigLineNo, 99999); // no FFLConfigLine row seeded for this key
        FieldLine.Validate(LineNo, 10000);
        FieldLine.Insert(true);

        FieldLine.CalcFields(TargetTableNo);
        Assert.AreEqual(0, FieldLine.TargetTableNo,
            'CalcFields on a lookup() FlowField with no matching source row must resolve to 0 (faithful "not found"), proving the fix reads real data rather than always matching');
    end;

    local procedure Initialize()
    var
        ConfigLine: Record FFLConfigLine;
        FieldLine: Record "FFL Field Line";
    begin
        ConfigLine.DeleteAll();
        FieldLine.DeleteAll();
    end;
}
