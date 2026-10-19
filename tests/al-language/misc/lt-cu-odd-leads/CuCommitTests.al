// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-commitbehavior-attribute
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT CU Row (85300), LT CU Inserter (85303), LT CU Failing Inserter (85304), LT CU Commit Sub (85307)
// Corpus #670 items 36, 40, 43, 44: [CommitBehavior] and the commit of a guarded Codeunit.Run, nested CommitBehavior scopes,
// CommitBehavior on a TryFunction, Commit inside table triggers, a table event subscriber and a TryFunction, Consistent(false) and Commit.
// Durability is read the way TestCommitBehaviorAttribute.al does it: an unrelated error after the call undoes every write since the last commit.
// BC versions: 27.5, 28.5, 29.0

codeunit 85311 "LT CU Commit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "LT CU Row";
    begin
        Row.DeleteAll();
        Commit();
        ClearLastError();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT CU Row";
        Ids: Text;
    begin
        if Row.FindSet() then
            repeat
                Ids += Format(Row.Id) + ';';
            until Row.Next() = 0;
        exit('[' + Ids + ']');
    end;

    local procedure NameOf(Id: Integer): Text
    var
        Row: Record "LT CU Row";
    begin
        if not Row.Get(Id) then
            exit('<missing>');
        exit(Row.Name);
    end;

    local procedure InsertRow(Id: Integer; Name: Text[50])
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := Id;
        Row.Name := Name;
        Row.Insert(true);
    end;

    // ---------------------------------------------------------------- item 36
    [CommitBehavior(CommitBehavior::Error)]
    local procedure ErrorScopeGuardedRun(CodeunitId: Integer; var Log: Text)
    begin
        Log += 'run=' + Format(Codeunit.Run(CodeunitId)) + ';';
        Log += 'lasterror=' + GetLastErrorText() + ';';
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure IgnoreScopeGuardedRun(CodeunitId: Integer; var Log: Text)
    begin
        Log += 'run=' + Format(Codeunit.Run(CodeunitId)) + ';';
        Log += 'lasterror=' + GetLastErrorText() + ';';
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure ErrorScopeStatementRun(CodeunitId: Integer)
    begin
        Codeunit.Run(CodeunitId);
    end;

    local procedure ErrorScopeGuardedRunThenFail(CodeunitId: Integer; var Log: Text)
    begin
        ErrorScopeGuardedRun(CodeunitId, Log);
        Error('unrelated');
    end;

    local procedure IgnoreScopeGuardedRunThenFail(CodeunitId: Integer; var Log: Text)
    begin
        IgnoreScopeGuardedRun(CodeunitId, Log);
        Error('unrelated');
    end;

    local procedure ErrorScopeStatementRunThenFail(CodeunitId: Integer)
    begin
        ErrorScopeStatementRun(CodeunitId);
        Error('unrelated');
    end;

    [Test]
    procedure CommitBehaviorError_GuardedRun_Commit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Initialize();
        asserterror ErrorScopeGuardedRunThenFail(Codeunit::"LT CU Inserter", Log);
        Observer.ObserveError('err');
        Observer.Observe('log', Log);
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'run=Yes;lasterror=;');
        Observer.Expect('rows', '[100;]');
        Observer.Verify();
    end;

    [Test]
    procedure CommitBehaviorIgnore_GuardedRun_Commit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Initialize();
        asserterror IgnoreScopeGuardedRunThenFail(Codeunit::"LT CU Inserter", Log);
        Observer.ObserveError('err');
        Observer.Observe('log', Log);
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'run=Yes;lasterror=;');
        Observer.Expect('rows', '[100;]');
        Observer.Verify();
    end;

    [Test]
    procedure CommitBehaviorError_GuardedRun_FailingCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Initialize();
        asserterror ErrorScopeGuardedRunThenFail(Codeunit::"LT CU Failing Inserter", Log);
        Observer.ObserveError('err');
        Observer.Observe('log', Log);
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('log', 'run=No;lasterror=failing run;');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure CommitBehaviorError_StatementRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        asserterror ErrorScopeStatementRunThenFail(Codeunit::"LT CU Inserter");
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 40
    [CommitBehavior(CommitBehavior::Error)]
    local procedure OuterErrorInnerIgnore(Id: Integer)
    begin
        InnerIgnoreCommit(Id);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure InnerIgnoreCommit(Id: Integer)
    begin
        InsertRow(Id, 'nested');
        Commit();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure OuterIgnoreInnerError(Id: Integer)
    begin
        InnerErrorCommit(Id);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure InnerErrorCommit(Id: Integer)
    begin
        InsertRow(Id, 'nested');
        Commit();
    end;

    local procedure OuterErrorInnerIgnoreThenFail(Id: Integer)
    begin
        OuterErrorInnerIgnore(Id);
        Error('unrelated');
    end;

    local procedure OuterIgnoreInnerErrorThenFail(Id: Integer)
    begin
        OuterIgnoreInnerError(Id);
        Error('unrelated');
    end;

    [TryFunction]
    [CommitBehavior(CommitBehavior::Error)]
    local procedure TryCommitUnderError()
    begin
        Commit();
    end;

    [TryFunction]
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure TryCommitUnderIgnore()
    begin
        Commit();
    end;

    [Test]
    procedure Nested_ErrorOuter_IgnoreInner()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        asserterror OuterErrorInnerIgnoreThenFail(1);
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.');
        Observer.Expect('err|code', 'DB:Ok');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_IgnoreOuter_ErrorInner()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        asserterror OuterIgnoreInnerErrorThenFail(2);
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.');
        Observer.Expect('err|code', 'DB:Ok');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_WithCommitBehavior()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('error try', Format(TryCommitUnderError()));
        Observer.ObserveError('error try last');
        Observer.Observe('ignore try', Format(TryCommitUnderIgnore()));
        Observer.ObserveError('ignore try last');
        Observer.Expect('error try', 'No');
        Observer.Expect('error try last|text', 'Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.');
        Observer.Expect('error try last|code', 'DB:Ok');
        Observer.Expect('ignore try', 'Yes');
        Observer.Expect('ignore try last|text', '');
        Observer.Expect('ignore try last|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure CommitWorksAgain_AfterErrorScopeFailed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        asserterror InnerErrorCommit(3);
        Observer.ObserveError('scope');
        InsertRow(4, 'after');
        Commit();
        asserterror Error('unrelated');
        Observer.Observe('rows', Rows());
        Observer.Expect('scope|text', 'Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.');
        Observer.Expect('scope|code', 'DB:Ok');
        Observer.Expect('rows', '[4;]');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 43
    local procedure InsertThenFail(Id: Integer; Name: Text[50])
    begin
        InsertRow(Id, Name);
        Error('unrelated');
    end;

    local procedure ModifyThenFail(Id: Integer; Name: Text[50])
    var
        Row: Record "LT CU Row";
    begin
        Row.Get(Id);
        Row.Name := Name;
        Row.Modify(true);
        Error('unrelated');
    end;

    [TryFunction]
    local procedure TryCommit()
    begin
        Commit();
    end;

    [Test]
    procedure Commit_InOnInsertTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        asserterror InsertThenFail(10, 'commit-in-oninsert');
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_InOnModifyTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        InsertRow(11, 'plain');
        Commit();
        asserterror ModifyThenFail(11, 'commit-in-onmodify');
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Observe('name', NameOf(11));
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('rows', '[11;]');
        Observer.Expect('name', 'plain');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_InTableEventSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT CU Commit Sub";
    begin
        Initialize();
        BindSubscription(Sub);
        asserterror InsertThenFail(12, 'commit-in-sub');
        UnbindSubscription(Sub);
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Observe('name', NameOf(12));
        Observer.Expect('err|text', 'unrelated');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('rows', '[12;]');
        Observer.Expect('name', 'commit-in-sub');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_InTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        InsertRow(13, 'before try');
        asserterror Ok := TryCommit();
        Observer.ObserveError('try');
        Observer.Observe('ok', Format(Ok));
        asserterror Error('unrelated');
        Observer.Observe('rows', Rows());
        Observer.Expect('try|text', 'Call to the function ''COMMIT'' is not allowed inside the call to ''RootMethodScope'' when it is used as a TryFunction.');
        Observer.Expect('try|code', 'TryFunctionWrite');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 44
    local procedure InconsistentInsertCommit(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Consistent(false);
        Row.Id := Id;
        Row.Insert();
        Commit();
    end;

    local procedure InconsistentThenConsistentCommit(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Consistent(false);
        Row.Id := Id;
        Row.Insert();
        Row.Consistent(true);
        Commit();
    end;

    [Test]
    procedure Consistent_False_ThenCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        InsertRow(20, 'committed before');
        Commit();
        asserterror InconsistentInsertCommit(21);
        Observer.ObserveError('err');
        Observer.Observe('rows', Rows());
        Observer.Expect('err|text', 'The transaction cannot be completed because it will cause inconsistencies in the LT CU Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('err|code', 'DB:TableInConsistent');
        Observer.Expect('rows', '[20;]');
        Observer.Verify();
    end;

    [Test]
    procedure Consistent_FalseThenTrue_ThenCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        InconsistentThenConsistentCommit(22);
        asserterror Error('unrelated');
        Observer.Observe('rows', Rows());
        Observer.Expect('rows', '[22;]');
        Observer.Verify();
    end;
}
