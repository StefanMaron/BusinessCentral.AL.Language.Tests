// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 67516, codeunit 67515
// Probe: Database.MinimumActiveRowVersion against LastUsedRowVersion() + 1 with no write, inside an open write transaction and after Commit (issue 580 item 8). The existing PlTDatabase.al checks only that it is not below zero and not above LastUsedRowVersion() + 1.
// BC versions: 27+

table 67516 "LT RV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67515 "LT RV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Snapshot(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        Observer.Observe(Name + '_min_minus_last', Format(Min - Last));
        Observer.Observe(Name + '_equals_last_plus_one', Format(Min = Last + 1));
        Observer.Observe(Name + '_min_positive', Format(Min > 0));
    end;

    [Test]
    procedure MinimumActiveRowVersion_NoWrite_Committed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Commit();
        Snapshot(Observer, 'after_commit_no_write');
        Snapshot(Observer, 'again');
        Observer.Observe('in_write_transaction', Format(IsInWriteTransaction()));
        Observer.Finish();
    end;

    [Test]
    procedure MinimumActiveRowVersion_InsideOpenWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Before: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        Before := MinimumActiveRowVersion();
        Row.Id := 1;
        Row.Insert();
        Observer.Observe('in_write_transaction', Format(IsInWriteTransaction()));
        Snapshot(Observer, 'after_insert');
        Observer.Observe('min_unchanged_by_open_insert', Format(MinimumActiveRowVersion() = Before));
        Row.Id := 2;
        Row.Insert();
        Snapshot(Observer, 'after_second_insert');
        Row.Name := 'x';
        Row.Modify();
        Snapshot(Observer, 'after_modify');
        Observer.Finish();
    end;

    [Test]
    procedure MinimumActiveRowVersion_AfterCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Before: BigInteger;
    begin
        Row.DeleteAll();
        Commit();
        Before := MinimumActiveRowVersion();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Observer.Observe('in_write_transaction', Format(IsInWriteTransaction()));
        Snapshot(Observer, 'after_commit');
        Observer.Observe('min_moved_by_commit', Format(MinimumActiveRowVersion() > Before));
        Row.DeleteAll();
        Commit();
        Observer.Finish();
    end;

    [Test]
    procedure MinimumActiveRowVersion_PrefixedCallEqualsBareCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Commit();
        Observer.Observe('prefixed_equals_bare', Format(Database.MinimumActiveRowVersion() = MinimumActiveRowVersion()));
        Observer.Observe('last_prefixed_equals_bare', Format(Database.LastUsedRowVersion() = LastUsedRowVersion()));
        Observer.Finish();
    end;
}
