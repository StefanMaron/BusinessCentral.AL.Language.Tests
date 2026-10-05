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
        asserterror Stale.Modify();
        Res := Outcome();
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
        asserterror Stale.Modify(true);
        Res := Outcome();
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
        asserterror Stale.Modify();
        Res := Outcome();
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
        asserterror Stale.Modify();
        Res := Outcome();
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
        asserterror Rec.Modify();
        Res := Outcome();
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
        asserterror Stale.Modify();
        Res := Outcome();
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
        asserterror Rec.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_A7 ' + Res);
    end;

    [Test]
    procedure Probe_B_StaleModify_AfterOtherModifyAll()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_B ' + Res);
    end;

    [Test]
    procedure Probe_B3_StaleDelete_AfterOtherModifyAll()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);
        asserterror Stale.Delete();
        Res := Outcome();
        Assert.Fail('PROBE_B3 ' + Res + ' | count=' + Format(Rec.Count()));
    end;

    [Test]
    procedure Probe_B4_Control_GetAfterModifyAll_ThenModify()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);
        Stale.Get(2);
        Stale."Integer Field" := 7;
        Stale.Modify();
        Rec.Get(2);
        Assert.Fail('PROBE_B4 accepted | stored=' + Format(Rec."Integer Field"));
    end;

    [Test]
    procedure Probe_B6_Temporary_ModifyAll_StaleModify()
    var
        Rec: Record "ALT Universal" temporary;
        Stale: Record "ALT Universal" temporary;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Copy(Rec, true);
        Stale.Get(2);
        Rec.ModifyAll("Integer Field", 42);
        Stale."Integer Field" := 7;
        Stale.Modify();
        Rec.Get(2);
        Assert.Fail('PROBE_B6 accepted | stored=' + Format(Rec."Integer Field"));
    end;

    [Test]
    procedure Probe_B7_SameVariable_ModifyAll_ThenModify()
    var
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Stale."Entry No." := 2;
        Stale.Insert();
        Stale.Get(2);
        Stale.ModifyAll("Integer Field", 42);
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_B7 ' + Res);
    end;

    [Test]
    procedure Probe_B8_StaleModify_AfterOtherModifyThenModifyAll()
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
        Rec."Integer Field" := 41;
        Rec.Modify();
        Rec.ModifyAll("Integer Field", 42);
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_B8 ' + Res);
    end;

    [Test]
    procedure Probe_A8_StaleModify_AfterOtherModifyAndCommit()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Commit();
        Stale.Get(2);
        Rec.Get(2);
        Rec."Integer Field" := 42;
        Rec.Modify();
        Commit();
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_A8 ' + Res);
    end;

    [Test]
    procedure Probe_A9_StaleModify_AfterOtherRenamedAway()
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
        Rec.Rename(2);
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_A9 ' + Res);
    end;

    [Test]
    procedure Probe_A10_StaleModify_AfterOtherDeletedAndReinserted()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Rec.Delete();
        Rec.Init();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_A10 ' + Res);
    end;

    [Test]
    procedure Probe_A11_StaleModify_AfterRecordRefModify()
    var
        Rec: Record "ALT Universal";
        Stale: Record "ALT Universal";
        Ref: RecordRef;
        Res: Text;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();
        Stale.Get(2);
        Ref.GetTable(Rec);
        Ref.Get(Rec.RecordId);
        Ref.Field(3).Value := 42;
        Ref.Modify();
        Stale."Integer Field" := 7;
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_A11 ' + Res);
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
        asserterror Stale.Modify();
        Res := Outcome();
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
        asserterror Stale.Delete();
        Res := Outcome();
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
        asserterror Stale.Delete();
        Res := Outcome();
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
        asserterror Stale.Modify();
        Res := Outcome();
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
        Stale.Modify();
        Rec.Get(2);
        Assert.Fail('PROBE_E accepted | stored=' + Format(Rec."Integer Field"));
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
        asserterror Stale.Modify();
        Res := Outcome();
        Assert.Fail('PROBE_G ' + Res);
    end;

    local procedure Outcome(): Text
    begin
        exit('code=' + GetLastErrorCode() + ' text=' + GetLastErrorText());
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
