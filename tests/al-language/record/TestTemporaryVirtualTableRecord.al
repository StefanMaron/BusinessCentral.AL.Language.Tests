// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Agg Perm Set (permissionset, 60930)
//
// CLAIM: a `temporary` record holds exactly the rows AL inserted into it, for every column,
// EVEN when the table it is a temporary instance of is a system VIRTUAL table whose
// non-temporary rows the platform computes on the fly ("Field" 2000000041, Date 2000000007,
// "Aggregate Permission Set" 2000000167). `temporary` borrows the table's SHAPE; the virtual
// provider that answers the non-temporary record never sees the temporary one.
//
// This is not a hypothetical shape. Base Application report 8621 "Config. Package - Process"
// builds its transformation rule set in a `Record "Field" temporary`, writes TableNo and
// "No." into it, and keys the rules off Format(TempField."No.") when it reads them back --
// so a temporary Field record that does not round-trip "No." silently reroutes RapidStart
// data transformation to the wrong rule instead of failing.
//
// Each table gets both directions, because a temporary record answering nothing and a
// temporary record answering the platform's own rows are different bugs and only one of them
// is visible from a positive assertion:
//   [POSITIVE] the value AL wrote reads back, and a column AL never wrote reads back its
//              type default rather than a value the platform computed;
//   [NEGATIVE] a key that genuinely EXISTS in the non-temporary table is NOT found in the
//              temporary one. The Field case asserts the contrast explicitly: Get() on the
//              same key succeeds on `Record Field` and fails on `Record Field temporary`, in
//              the same test, so neither half can be satisfied by a provider that always
//              answers true or always answers false.

codeunit 60118 "Test Temporary Virtual Tbl Rec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ── "Field" (2000000041) ────────────────────────────────────────────────────────────

    [Test]
    procedure Record_Field_Temporary_RoundTripsTheValuesAlWrote()
    // CLAIM: a Record "Field" temporary reads back the TableNo and "No." AL wrote, holds
    // exactly the one row AL inserted, and leaves a column AL never wrote at its default.
    var
        TempFieldRec: Record "Field" temporary;
    begin
        Initialize();

        // [GIVEN] one row AL wrote itself, under a field number ALT Universal does not declare
        TempFieldRec.Init();
        TempFieldRec.TableNo := Database::"ALT Universal";
        TempFieldRec."No." := 999;
        TempFieldRec.Insert();

        // [WHEN] reading it back under the same TableNo filter the platform would use
        TempFieldRec.Reset();
        TempFieldRec.SetRange(TableNo, Database::"ALT Universal");

        // [THEN] the temporary record holds that row and nothing else
        Assert.AreEqual(1, TempFieldRec.Count(), 'A temporary Field record must hold exactly the one row AL inserted.');
        Assert.IsTrue(TempFieldRec.FindSet(), 'FindSet must find the row AL inserted into the temporary Field record.');
        Assert.AreEqual(999, TempFieldRec."No.", 'A temporary Field record must read back the "No." AL wrote.');
        Assert.AreEqual(Database::"ALT Universal", TempFieldRec.TableNo, 'A temporary Field record must read back the TableNo AL wrote.');
        Assert.AreEqual('', TempFieldRec.FieldName, 'FieldName was never written by AL and must stay blank.');
        Assert.AreEqual(0, TempFieldRec.Next(), 'A temporary Field record must not carry a second row AL never inserted.');
    end;

    [Test]
    procedure Record_Field_Temporary_DoesNotAnswerFromRealFieldMetadata()
    // CLAIM: field 1 of ALT Universal ("Entry No.") is a row of the non-temporary Field
    // table, and is NOT a row of a temporary Field record AL never put it in. Both halves are
    // asserted here, on the same key, so the test cannot pass by always answering true or
    // always answering false.
    var
        FieldRec: Record "Field";
        TempFieldRec: Record "Field" temporary;
    begin
        Initialize();

        // [GIVEN] the non-temporary Field table does have that row, with its declared name
        Assert.IsTrue(
            FieldRec.Get(Database::"ALT Universal", 1),
            'The non-temporary Field table must have a row for field 1 of ALT Universal.');
        Assert.AreEqual('Entry No.', FieldRec.FieldName, 'Field 1 of ALT Universal is "Entry No.".');

        // [WHEN] a temporary Field record is given a DIFFERENT row
        TempFieldRec.Init();
        TempFieldRec.TableNo := Database::"ALT Universal";
        TempFieldRec."No." := 999;
        TempFieldRec.Insert();

        // [THEN] the row the platform computes is not visible through the temporary record
        Assert.IsFalse(
            TempFieldRec.Get(Database::"ALT Universal", 1),
            'A temporary Field record must not answer from the platform''s real field metadata.');
    end;

    [Test]
    procedure Record_Field_Temporary_DeleteStaysInTheTemporaryRecord()
    // CLAIM: Delete and DeleteAll on a Record "Field" temporary remove exactly the rows AL
    // named from the temporary record, and never reach the real Field table -- even for a row
    // whose key (ALT Universal, field 1) is also a real row of the non-temporary table.
    var
        FieldRec: Record "Field";
        TempFieldRec: Record "Field" temporary;
    begin
        Initialize();

        // [GIVEN] three rows AL wrote, one of them on the key of a real Field row
        InsertTempField(TempFieldRec, 1);
        InsertTempField(TempFieldRec, 998);
        InsertTempField(TempFieldRec, 999);

        // [WHEN] one row is deleted by Get + Delete, and another by a filtered DeleteAll
        Assert.IsTrue(TempFieldRec.Get(Database::"ALT Universal", 998), 'Get must find row 998 AL inserted.');
        TempFieldRec.Delete();
        TempFieldRec.Reset();
        TempFieldRec.SetRange(TableNo, Database::"ALT Universal");
        TempFieldRec.SetRange("No.", 1);
        TempFieldRec.DeleteAll();

        // [THEN] only row 999 remains in the temporary record
        TempFieldRec.Reset();
        Assert.AreEqual(1, TempFieldRec.Count(), 'Exactly one of the three rows AL inserted must remain after deleting two.');
        Assert.IsTrue(TempFieldRec.FindFirst(), 'The remaining row must still be found.');
        Assert.AreEqual(999, TempFieldRec."No.", 'The remaining row must be the one AL did not delete.');
        Assert.IsFalse(TempFieldRec.Get(Database::"ALT Universal", 998), 'Row 998 was deleted by Delete and must be gone.');
        Assert.IsFalse(TempFieldRec.Get(Database::"ALT Universal", 1), 'Row 1 was deleted by DeleteAll and must be gone.');

        // [THEN] the real Field table still has field 1 of ALT Universal
        Assert.IsTrue(
            FieldRec.Get(Database::"ALT Universal", 1),
            'Deleting from a temporary Field record must not remove the real Field row.');
        Assert.AreEqual('Entry No.', FieldRec.FieldName, 'The real Field row must be unchanged.');
    end;

    // ── Date (2000000007) ───────────────────────────────────────────────────────────────

    [Test]
    procedure Record_Date_Temporary_RoundTripsTheValuesAlWrote()
    // CLAIM: a Record Date temporary holds the one period row AL inserted, reads back the
    // "Period Name" AL wrote, and does not gain the calendar days the platform computes for
    // the same filtered range.
    var
        TempDateRec: Record Date temporary;
    begin
        Initialize();

        // [GIVEN] one row AL wrote itself, inside January 2099
        TempDateRec.Init();
        TempDateRec."Period Type" := TempDateRec."Period Type"::Date;
        TempDateRec."Period Start" := DMY2Date(15, 1, 2099);
        TempDateRec."Period Name" := 'ALTTEMP';
        TempDateRec.Insert();

        // [WHEN] reading it back under a closed range covering the whole month
        TempDateRec.Reset();
        TempDateRec.SetRange("Period Type", TempDateRec."Period Type"::Date);
        TempDateRec.SetRange("Period Start", DMY2Date(1, 1, 2099), DMY2Date(31, 1, 2099));

        // [THEN] the 31 real days of January 2099 are not there -- only AL's row is
        Assert.AreEqual(1, TempDateRec.Count(), 'A temporary Date record must hold exactly the one row AL inserted.');
        Assert.IsTrue(TempDateRec.FindSet(), 'FindSet must find the row AL inserted into the temporary Date record.');
        Assert.AreEqual(DMY2Date(15, 1, 2099), TempDateRec."Period Start", 'A temporary Date record must read back the "Period Start" AL wrote.');
        Assert.AreEqual('ALTTEMP', TempDateRec."Period Name", 'A temporary Date record must read back the "Period Name" AL wrote, not a computed weekday name.');
        Assert.AreEqual(0, TempDateRec."Period No.", '"Period No." was never written by AL and must stay 0.');
        Assert.AreEqual(0, TempDateRec.Next(), 'A temporary Date record must not carry a second row AL never inserted.');
    end;

    [Test]
    procedure Record_Date_Temporary_DoesNotAnswerFromTheComputedCalendar()
    // CLAIM: 16 January 2099 is a row of the non-temporary Date table and is NOT a row of a
    // temporary Date record AL never put it in.
    var
        DateRec: Record Date;
        TempDateRec: Record Date temporary;
    begin
        Initialize();

        // [GIVEN] the non-temporary Date table computes that day
        Assert.IsTrue(
            DateRec.Get(DateRec."Period Type"::Date, DMY2Date(16, 1, 2099)),
            'The non-temporary Date table must have a Date-type row for 16 January 2099.');

        // [WHEN] a temporary Date record is given a DIFFERENT day
        TempDateRec.Init();
        TempDateRec."Period Type" := TempDateRec."Period Type"::Date;
        TempDateRec."Period Start" := DMY2Date(15, 1, 2099);
        TempDateRec.Insert();

        // [THEN] the computed day is not visible through the temporary record
        Assert.IsFalse(
            TempDateRec.Get(TempDateRec."Period Type"::Date, DMY2Date(16, 1, 2099)),
            'A temporary Date record must not answer from the platform''s computed calendar.');
    end;

    [Test]
    procedure Record_Date_Temporary_DeleteStaysInTheTemporaryRecord()
    // CLAIM: Delete and DeleteAll on a Record Date temporary remove exactly the rows AL named,
    // and the non-temporary Date table still computes the same days afterwards.
    var
        DateRec: Record Date;
        TempDateRec: Record Date temporary;
    begin
        Initialize();

        // [GIVEN] three days AL wrote into January 2099
        InsertTempDate(TempDateRec, DMY2Date(15, 1, 2099));
        InsertTempDate(TempDateRec, DMY2Date(16, 1, 2099));
        InsertTempDate(TempDateRec, DMY2Date(17, 1, 2099));

        // [WHEN] one row is deleted by Get + Delete, and another by a filtered DeleteAll
        Assert.IsTrue(TempDateRec.Get(TempDateRec."Period Type"::Date, DMY2Date(16, 1, 2099)), 'Get must find 16 January 2099 AL inserted.');
        TempDateRec.Delete();
        TempDateRec.Reset();
        TempDateRec.SetRange("Period Type", TempDateRec."Period Type"::Date);
        TempDateRec.SetRange("Period Start", DMY2Date(15, 1, 2099));
        TempDateRec.DeleteAll();

        // [THEN] only 17 January remains in the temporary record
        TempDateRec.Reset();
        Assert.AreEqual(1, TempDateRec.Count(), 'Exactly one of the three rows AL inserted must remain after deleting two.');
        Assert.IsTrue(TempDateRec.FindFirst(), 'The remaining row must still be found.');
        Assert.AreEqual(DMY2Date(17, 1, 2099), TempDateRec."Period Start", 'The remaining row must be the one AL did not delete.');

        // [THEN] the non-temporary Date table still computes both deleted days
        Assert.IsTrue(
            DateRec.Get(DateRec."Period Type"::Date, DMY2Date(15, 1, 2099)),
            'Deleting from a temporary Date record must not remove 15 January 2099 from the real Date table.');
        Assert.IsTrue(
            DateRec.Get(DateRec."Period Type"::Date, DMY2Date(16, 1, 2099)),
            'Deleting from a temporary Date record must not remove 16 January 2099 from the real Date table.');
    end;

    // ── "Aggregate Permission Set" (2000000167) ─────────────────────────────────────────

    [Test]
    procedure Record_AggregatePermissionSet_Temporary_RoundTripsTheValuesAlWrote()
    // CLAIM: a Record "Aggregate Permission Set" temporary holds the one row AL inserted and
    // reads back the "Role ID" AL wrote, rather than the union of Metadata and Tenant
    // Permission Set rows the platform re-derives for the non-temporary record.
    var
        TempAggPermSet: Record "Aggregate Permission Set" temporary;
        ThisModule: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        // [GIVEN] one row AL wrote itself, under a role id no app declares
        TempAggPermSet.Init();
        TempAggPermSet.Scope := TempAggPermSet.Scope::System;
        TempAggPermSet."App ID" := ThisModule.Id();
        TempAggPermSet."Role ID" := 'ALT TEMP ROLE';
        TempAggPermSet.Insert();

        // [WHEN] reading it back
        TempAggPermSet.Reset();

        // [THEN] the platform's own permission sets are not there -- only AL's row is
        Assert.AreEqual(1, TempAggPermSet.Count(), 'A temporary Aggregate Permission Set record must hold exactly the one row AL inserted.');
        Assert.IsTrue(TempAggPermSet.FindSet(), 'FindSet must find the row AL inserted into the temporary Aggregate Permission Set record.');
        Assert.AreEqual('ALT TEMP ROLE', TempAggPermSet."Role ID", 'A temporary Aggregate Permission Set record must read back the "Role ID" AL wrote.');
        Assert.AreEqual('', TempAggPermSet.Name, 'Name was never written by AL and must stay blank.');
        Assert.AreEqual(0, TempAggPermSet.Next(), 'A temporary Aggregate Permission Set record must not carry a second row AL never inserted.');
    end;

    [Test]
    procedure Record_AggregatePermissionSet_Temporary_DoesNotAnswerFromDeclaredPermissionSets()
    // CLAIM: this app's own "ALT Agg Perm Set" is a row of the non-temporary Aggregate
    // Permission Set table (see codeunit 60931) and is NOT a row of a temporary one.
    var
        AggPermSet: Record "Aggregate Permission Set";
        TempAggPermSet: Record "Aggregate Permission Set" temporary;
        ThisModule: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        // [GIVEN] the non-temporary table does carry this app's declared permission set
        Assert.IsTrue(
            AggPermSet.Get(AggPermSet.Scope::System, ThisModule.Id(), 'ALT Agg Perm Set'),
            'The non-temporary Aggregate Permission Set table must carry this app''s declared permission set.');

        // [WHEN] a temporary record is given a DIFFERENT row
        TempAggPermSet.Init();
        TempAggPermSet.Scope := TempAggPermSet.Scope::System;
        TempAggPermSet."App ID" := ThisModule.Id();
        TempAggPermSet."Role ID" := 'ALT TEMP ROLE';
        TempAggPermSet.Insert();

        // [THEN] the declared permission set is not visible through the temporary record
        Assert.IsFalse(
            TempAggPermSet.Get(AggPermSet.Scope::System, ThisModule.Id(), 'ALT Agg Perm Set'),
            'A temporary Aggregate Permission Set record must not answer from the platform''s declared permission sets.');
    end;

    [Test]
    procedure Record_AggregatePermissionSet_Temporary_DeleteStaysInTheTemporaryRecord()
    // CLAIM: Delete and DeleteAll on a Record "Aggregate Permission Set" temporary remove
    // exactly the rows AL named -- including a row on the key of this app's REAL declared
    // permission set -- and the non-temporary table still carries that permission set.
    var
        AggPermSet: Record "Aggregate Permission Set";
        TempAggPermSet: Record "Aggregate Permission Set" temporary;
        ThisModule: ModuleInfo;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        // [GIVEN] three rows AL wrote, one of them on the key of the real "ALT Agg Perm Set"
        InsertTempAggPermSet(TempAggPermSet, ThisModule.Id(), 'ALT Agg Perm Set');
        InsertTempAggPermSet(TempAggPermSet, ThisModule.Id(), 'ALT TEMP ROLE A');
        InsertTempAggPermSet(TempAggPermSet, ThisModule.Id(), 'ALT TEMP ROLE B');

        // [WHEN] one row is deleted by Get + Delete, and another by a filtered DeleteAll
        Assert.IsTrue(
            TempAggPermSet.Get(TempAggPermSet.Scope::System, ThisModule.Id(), 'ALT TEMP ROLE A'),
            'Get must find the row AL inserted.');
        TempAggPermSet.Delete();
        TempAggPermSet.Reset();
        TempAggPermSet.SetRange("Role ID", 'ALT Agg Perm Set');
        TempAggPermSet.DeleteAll();

        // [THEN] only ALT TEMP ROLE B remains in the temporary record
        TempAggPermSet.Reset();
        Assert.AreEqual(1, TempAggPermSet.Count(), 'Exactly one of the three rows AL inserted must remain after deleting two.');
        Assert.IsTrue(TempAggPermSet.FindFirst(), 'The remaining row must still be found.');
        Assert.AreEqual('ALT TEMP ROLE B', TempAggPermSet."Role ID", 'The remaining row must be the one AL did not delete.');

        // [THEN] the non-temporary table still carries this app's declared permission set
        Assert.IsTrue(
            AggPermSet.Get(AggPermSet.Scope::System, ThisModule.Id(), 'ALT Agg Perm Set'),
            'Deleting from a temporary Aggregate Permission Set record must not remove the real declared permission set.');
    end;

    local procedure InsertTempField(var TempFieldRec: Record "Field" temporary; FieldNo: Integer)
    begin
        TempFieldRec.Init();
        TempFieldRec.TableNo := Database::"ALT Universal";
        TempFieldRec."No." := FieldNo;
        TempFieldRec.Insert();
    end;

    local procedure InsertTempDate(var TempDateRec: Record Date temporary; PeriodStart: Date)
    begin
        TempDateRec.Init();
        TempDateRec."Period Type" := TempDateRec."Period Type"::Date;
        TempDateRec."Period Start" := PeriodStart;
        TempDateRec.Insert();
    end;

    local procedure InsertTempAggPermSet(var TempAggPermSet: Record "Aggregate Permission Set" temporary; AppId: Guid; RoleId: Code[20])
    begin
        TempAggPermSet.Init();
        TempAggPermSet.Scope := TempAggPermSet.Scope::System;
        TempAggPermSet."App ID" := AppId;
        TempAggPermSet."Role ID" := RoleId;
        TempAggPermSet.Insert();
    end;

    local procedure Initialize()
    begin
        // Every record this codeunit touches is either `temporary` -- a fresh, empty store per
        // test procedure, so there is nothing to clean up -- or one of the three system
        // virtual tables, which are computed by the platform and cannot be deleted from.
    end;
}
