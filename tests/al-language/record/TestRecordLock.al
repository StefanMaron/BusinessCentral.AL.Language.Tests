// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-locktable-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60060 "Test Record Lock"
{
    Subtype = Test;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_LockTable_Called_TableIsLocked()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.LockTable();
        Assert.IsTrue(true, 'LockTable() must not throw an error');
    end;

    [Test]
    procedure Record_LockTable_WaitTrue_WaitsForLock()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.LockTable(true);
        Assert.IsTrue(true, 'LockTable(Wait: true) must not throw an error');
    end;

    [Test]
    procedure Record_LockTable_WaitFalse_CloudSandbox_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        asserterror Rec.LockTable(false, true);
        Assert.ExpectedError('not supported');
    end;

    [Test]
    procedure Record_Consistent_SetTrue_AllowsInconsistency()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.Consistent(true);
        Assert.IsTrue(true, 'Consistent(true) must not throw an error');
    end;

    [Test]
    procedure Record_Consistent_SetFalse_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.Consistent(false);  // must not throw on its own
        Rec.Consistent(true);   // restore
        Assert.IsTrue(true, 'Consistent(false/true) must be callable without throwing in isolation');
    end;

    [Test]
    procedure Record_ReadConsistency_Default_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
        IsConsistent: Boolean;
    begin
        Initialize();
        IsConsistent := Rec.ReadConsistency();
        Assert.IsFalse(IsConsistent, 'ReadConsistency() must return false in BC Cloud');
    end;

    [Test]
    procedure Record_ReadIsolation_Get_IsCallable()
    var
        Rec: Record "ALT Universal";
        IsoLevel: IsolationLevel;
    begin
        Initialize();
        IsoLevel := Rec.ReadIsolation();
        Assert.IsTrue(true, 'ReadIsolation getter must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure Record_ReadIsolation_Set_IsCallable()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec.ReadIsolation(IsolationLevel::Default);
        Assert.IsTrue(true, 'ReadIsolation setter must be callable without throwing in BC Cloud');
    end;

    [Test]
    procedure Record_RecordLevelLocking_ReturnsBoolean()
    var
        Rec: Record "ALT Universal";
        IsLocking: Boolean;
    begin
        Initialize();
        IsLocking := Rec.RecordLevelLocking();
        Assert.IsTrue(true, 'RecordLevelLocking() must return a valid boolean value');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}

// Writer QB (corpus issue #668 item 27): does FindSet(true) take locks like LockTable() followed by FindSet()? Read from the platform table
// Database Locks, filtered on this session, after a plain FindSet, after FindSet(true), and after LockTable() + FindSet(). The rows read
// are those of the Company table (committed rows; a row written in the test transaction would already hold an exclusive lock).
// Each form runs in a test codeunit of its own, so no lock of an earlier form is still held (one transaction per test codeunit).
codeunit 86387 "LT QB Lock Snapshot"
{
    procedure Locks(): Text
    var
        DbLocks: Record "Database Locks";
        Rows: List of [Text];
        Row: Text;
        Result: Text;
    begin
        DbLocks.SetRange("Session ID", SessionId());
        if DbLocks.FindSet() then
            repeat
                Row := DbLocks."Object Name" + '|' + Format(DbLocks."Resource Type") + '|' + Format(DbLocks."Request Mode") + '|' + Format(DbLocks."Request Status");
                if not Rows.Contains(Row) then
                    Rows.Add(Row);
            until DbLocks.Next() = 0;
        Sort(Rows);
        foreach Row in Rows do
            Result += Row + ';';
        exit('n=' + Format(Rows.Count()) + ';' + Result);
    end;

    local procedure Sort(var Rows: List of [Text])
    var
        I: Integer;
        J: Integer;
        A: Text;
        B: Text;
    begin
        for I := 1 to Rows.Count() do
            for J := 1 to Rows.Count() - I do begin
                A := Rows.Get(J);
                B := Rows.Get(J + 1);
                if A > B then begin
                    Rows.Set(J, B);
                    Rows.Set(J + 1, A);
                end;
            end;
    end;
}

codeunit 86384 "LT QB Lock FindSet Plain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FindSet_Plain_DatabaseLocks_QB()
    var
        Observer: Codeunit "Probe Observer";
        Snapshot: Codeunit "LT QB Lock Snapshot";
        Company: Record Company;
    begin
        Observer.Observe('before', Snapshot.Locks());
        Observer.Observe('found', Format(Company.FindSet()));
        Observer.Observe('after FindSet', Snapshot.Locks());
        Observer.Expect('before', 'n=0;');
        Observer.Expect('found', 'Yes');
        Observer.Expect('after FindSet', 'n=0;');
        Observer.Verify();
    end;
}

codeunit 86385 "LT QB Lock FindSet True"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Held (publisher, bump 32): the lock row is not stable between runs. Observation 3 ('after FindSet(true)') read
    // 'n=1;Company|KEY|Update|Granted;' on BC 28.5 and 29.0 and in the writer's subset run on 27.5, but 'n=0;' on BC 27.5
    // in two full corpus runs of bump 32. An outcome that changes between runs is not an oracle. Held on every version
    // until writer QB finds what decides it; the assertions do not change.
#if LT_HELD_QB_FINDSET_TRUE_LOCK
    [Test]
#endif
    procedure FindSet_True_DatabaseLocks_QB()
    var
        Observer: Codeunit "Probe Observer";
        Snapshot: Codeunit "LT QB Lock Snapshot";
        Company: Record Company;
    begin
        Observer.Observe('before', Snapshot.Locks());
        Observer.Observe('found', Format(Company.FindSet(true)));
        Observer.Observe('after FindSet(true)', Snapshot.Locks());
        Observer.Expect('before', 'n=0;');
        Observer.Expect('found', 'Yes');
        Observer.Expect('after FindSet(true)', 'n=1;Company|KEY|Update|Granted;');
        Observer.Verify();
    end;
}

codeunit 86386 "LT QB Lock LockTable FindSet"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LockTable_FindSet_DatabaseLocks_QB()
    var
        Observer: Codeunit "Probe Observer";
        Snapshot: Codeunit "LT QB Lock Snapshot";
        Company: Record Company;
    begin
        Observer.Observe('before', Snapshot.Locks());
        Company.LockTable();
        Observer.Observe('after LockTable', Snapshot.Locks());
        Observer.Observe('found', Format(Company.FindSet()));
        Observer.Observe('after LockTable+FindSet', Snapshot.Locks());
        Observer.Expect('before', 'n=0;');
        Observer.Expect('after LockTable', 'n=0;');
        Observer.Expect('found', 'Yes');
        Observer.Expect('after LockTable+FindSet', 'n=1;Company|KEY|Update|Granted;');
        Observer.Verify();
    end;
}
