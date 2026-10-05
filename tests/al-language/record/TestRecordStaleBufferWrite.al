// PROBE (AlRunner#5204): records what the service tier does with a write through a stale buffer.
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 69920 "Test Record Stale Buffer Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Probe_A_StaleModify_ViaSecondVariable()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Rec.Get(2);
        Assert.Fail('PROBE_A ' + Res + ' | stored=' + Format(Rec."Integer Field"));
    end;

    [Test]
    procedure Probe_A2_StaleModifyTrue_ViaSecondVariable()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify(true);
        Stale."Integer Field" := 7;
        Res := Outcome(TryModifyTrue(Stale));
        Assert.Fail('PROBE_A2 ' + Res);
    end;

    [Test]
    procedure Probe_A3_StaleModify_NoFieldChangedByStale()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Res := Outcome(TryModify(Stale));
        Assert.Fail('PROBE_A3 ' + Res);
    end;

    [Test]
    procedure Probe_A4_StaleModify_ViaFindSet()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.FindFirst();
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Assert.Fail('PROBE_A4 ' + Res);
    end;

    [Test]
    procedure Probe_A5_Control_SameVariableModifiesTwice()
    var
        Rec: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Rec."Integer Field" := 43;
        Res := Outcome(TryModify(Rec));
        Assert.Fail('PROBE_A5 ' + Res);
    end;

    [Test]
    procedure Probe_A6_Control_SecondVariableGetsFreshThenModifies()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Stale.Get(2);
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Assert.Fail('PROBE_A6 ' + Res);
    end;

    [Test]
    procedure Probe_A7_StaleModify_InsertingVariableItself()
    var
        Rec: Record "ALT Universal";
        Other: Record "ALT Universal";
        Res: Text;
    begin
        // Insert through Rec (no Get), modify through Other, then modify through Rec again.
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Other.Get(2);
        Other."Integer Field" := 42;
        Other.Modify();
        Rec."Integer Field" := 7;
        Res := Outcome(TryModify(Rec));
        Assert.Fail('PROBE_A7 ' + Res);
    end;

    [Test]
    procedure Probe_C_StaleModify_AfterOtherRenamed()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec.Rename(3);
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Assert.Fail('PROBE_C ' + Res);
    end;

    [Test]
    procedure Probe_D_StaleDelete_ViaSecondVariable()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Res := Outcome(TryDelete(Stale));
        Assert.Fail('PROBE_D ' + Res + ' | count=' + Format(Rec.Count()));
    end;

    [Test]
    procedure Probe_D2_StaleDelete_AfterOtherDeleted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec.Delete();
        Res := Outcome(TryDelete(Stale));
        Assert.Fail('PROBE_D2 ' + Res);
    end;

    [Test]
    procedure Probe_D3_StaleModify_AfterOtherDeleted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Get(2);
        Rec.Delete();
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Assert.Fail('PROBE_D3 ' + Res);
    end;

    [Test]
    procedure Probe_E_Temporary_SharedBuffer_StaleModify()
    var
        Rec: Record "ALT Universal" temporary;
        Stale: Record "ALT Universal" temporary;
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Copy(Rec, true);
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Rec.Get(2);
        Assert.Fail('PROBE_E ' + Res + ' | stored=' + Format(Rec."Integer Field"));
    end;

    [Test]
    procedure Probe_G_LockedGet_StaleModify()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.LockTable();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Stale."Integer Field" := 7;
        Res := Outcome(TryModify(Stale));
        Assert.Fail('PROBE_G ' + Res);
    end;

    [TryFunction]
    local procedure TryModify(var Rec: Record "ALT Universal")
    begin
        Rec.Modify();
    end;

    [TryFunction]
    local procedure TryModifyTrue(var Rec: Record "ALT Universal")
    begin
        Rec.Modify(true);
    end;

    [TryFunction]
    local procedure TryDelete(var Rec: Record "ALT Universal")
    begin
        Rec.Delete();
    end;

    local procedure Outcome(Succeeded: Boolean): Text
    begin
        if Succeeded then
            exit('<none>');
        exit('code=' + GetLastErrorCode() + ' text=' + GetLastErrorText());
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
