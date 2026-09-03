// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-method
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Base (60007); shared Assert (60021)
//
// TestIsolationRollbackScope (60897) pins that under TestIsolation = Codeunit (the
// default), a row one [Test] writes without committing IS still visible to the next
// [Test] on the same codeunit instance. This pins the override: a [Test] procedure
// carrying [TransactionModel(TransactionModel::AutoRollback)] gets its OWN writes
// rolled back the moment it finishes — pass or fail — regardless of the codeunit's
// overall TestIsolation mode. The attribute is a per-TEST-METHOD override, not a
// codeunit-wide setting.
//
// The three tests below are declaration-ordered and share a codeunit, mirroring
// TestIsolationRollbackScope's own convention.
//   Test01 (AutoRollback): writes a uniquely-keyed row, does not Commit.
//   Test02 (no attribute — plain AutoCommit default): asks whether Test01's row
//     survived. It must NOT: TransactionModel::AutoRollback is what rolled it back,
//     not TestIsolation = Codeunit rolling back between every test (which
//     TestIsolationRollbackScope already showed does not happen on its own).
//   Test02 then writes its OWN uniquely-keyed row (no attribute, no Commit) to prove
//     the DEFAULT behaviour is unaffected by the previous test's attribute — that row
//     DOES survive into Test03, exactly like TestIsolationRollbackScope's own pair.
//   Test03 (no attribute): confirms Test02's row survived.
//
// BC also rolls an AutoRollback test back on an unhandled failure, not only on a
// normal return (observable in the platform's own test-execution loop: the same
// Session.Rollback() call sits in both the success switch and the surrounding
// catch(Exception) block). That half is not pinned here — a corpus test whose own
// [Test] procedure is *expected* to report FAIL is not expressible without making
// this suite permanently non-green, unlike every other corpus codeunit.
codeunit 60899 "Test TxModel AutoRollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure Test01_AutoRollbackWritesARowWithoutCommitting()
    var
        Base: Record "ALT Base";
    begin
        if Base.Get(60899001) then
            Base.Delete();

        Base.Init();
        Base."Entry No." := 60899001;
        Base."Name" := 'txmodel-autorollback-probe';
        Base.Insert();

        Assert.IsTrue(Base.Get(60899001), 'The probe row must exist inside the test that wrote it.');
    end;

    [Test]
    procedure Test02_PriorAutoRollbackRowDidNotSurvive_ThenWritesItsOwnDefaultRow()
    var
        Base: Record "ALT Base";
    begin
        Assert.IsFalse(
            Base.Get(60899001),
            'TransactionModel::AutoRollback on the PREVIOUS test must roll its own uncommitted ' +
            'write back the moment that test finished, regardless of TestIsolation = Codeunit ' +
            '(which on its own would have left the row visible here — see TestIsolationRollbackScope).');

        if Base.Get(60899002) then
            Base.Delete();

        Base.Init();
        Base."Entry No." := 60899002;
        Base."Name" := 'txmodel-default-probe';
        Base.Insert();
    end;

    [Test]
    procedure Test03_DefaultModelRowFromPriorTestDidSurvive()
    var
        Base: Record "ALT Base";
    begin
        Assert.IsTrue(
            Base.Get(60899002),
            'A [Test] with no TransactionModel override is unaffected by the previous AutoRollback ' +
            'test: its own uncommitted write still survives into the next test on the same ' +
            'codeunit, exactly as TestIsolationRollbackScope pins for the codeunit-wide default.');

        Base.Delete();
    end;
}
