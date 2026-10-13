// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68214
// Probe: written against a real BC 27.5 service tier (UTC session); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins when SystemCreatedAt and SystemModifiedAt are stamped (the host clock in UTC, to the
// millisecond; a Modify that changes nothing does not stamp, a change to a BLOB alone does), that a
// temporary record has no stamps and no SystemId, that Insert ignores a SystemId in the buffer unless
// InsertWithSystemId is true, that SystemId is set before OnInsert runs, and the texts of the duplicate
// SystemId and the ModifyAll SystemId errors.
// BC versions: 27.5

table 68214 "Probe Sys Fields"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Pay; Blob) { }
        field(4; Seen; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Seen := 'sysid-set=' + Format(not IsNullGuid(Rec.SystemId)) + ' xRec-sysid-null=' + Format(IsNullGuid(xRec.SystemId));
    end;
}

codeunit 68213 "Probe System Field Stamps"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        SysFields: Record "Probe Sys Fields";
    begin
        SysFields.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Insert_StampsBothFieldsWithTheUtcClock_SystemIdIsSetBeforeOnInsert()
    var
        SysFields: Record "Probe Sys Fields";
        Before: DateTime;
    begin
        Initialize();
        Before := CurrentDateTime();

        SysFields.Id := 1;
        SysFields.Insert(true);
        SysFields.Get(1);

        Assert.AreEqual('sysid-set=Yes xRec-sysid-null=Yes', SysFields.Seen, 'SystemId is set before OnInsert, xRec has none');
        Assert.IsTrue(Abs(SysFields.SystemCreatedAt - Before) < 5000, 'SystemCreatedAt is the current time');
        Assert.AreEqual(SysFields.SystemCreatedAt, SysFields.SystemModifiedAt, 'both equal on insert');
        Assert.IsTrue(Format(SysFields.SystemCreatedAt, 0, 9).EndsWith('Z'), 'UTC');
        Assert.AreEqual(Today(), DT2Date(CurrentDateTime()), 'Today and the date of CurrentDateTime agree');
        Assert.IsTrue(SysFields.SystemCreatedBy = UserSecurityId(), 'SystemCreatedBy');
    end;

    [Test]
    procedure Modify_StampsOnlyWhenAStoredFieldChanges_BlobCountsByContent()
    var
        SysFields: Record "Probe Sys Fields";
        OutStr: OutStream;
        Created: DateTime;
        Modified: DateTime;
    begin
        Initialize();
        SysFields.Id := 1;
        SysFields.Insert(true);
        SysFields.Get(1);
        Created := SysFields.SystemCreatedAt;
        Modified := SysFields.SystemModifiedAt;
        Sleep(20);

        SysFields.Txt := 'x';
        SysFields.Modify();
        SysFields.Get(1);
        Assert.AreEqual(Created, SysFields.SystemCreatedAt, 'SystemCreatedAt never changes');
        Assert.IsTrue(SysFields.SystemModifiedAt > Modified, 'a changed field stamps SystemModifiedAt');

        Modified := SysFields.SystemModifiedAt;
        Sleep(20);
        SysFields.Modify();
        SysFields.Get(1);
        Assert.AreEqual(Modified, SysFields.SystemModifiedAt, 'Modify without a change');

        SysFields.Txt := 'x';
        SysFields.Modify();
        SysFields.Get(1);
        Assert.AreEqual(Modified, SysFields.SystemModifiedAt, 'Modify with the same value');

        SysFields.Pay.CreateOutStream(OutStr);
        OutStr.WriteText('blob');
        SysFields.Modify();
        SysFields.Get(1);
        Assert.IsTrue(SysFields.SystemModifiedAt > Modified, 'a change to the BLOB alone stamps');
    end;

    [Test]
    procedure TemporaryRecord_HasNoStampsAndNoSystemId()
    var
        TempFields: Record "Probe Sys Fields" temporary;
    begin
        TempFields.Id := 1;
        TempFields.Insert(true);
        Assert.AreEqual(0DT, TempFields.SystemCreatedAt, 'SystemCreatedAt');
        Assert.IsTrue(IsNullGuid(TempFields.SystemId), 'SystemId is the null Guid');

        TempFields.Get(1);
        Assert.AreEqual(0DT, TempFields.SystemCreatedAt, 'after Get');
        Assert.IsTrue(IsNullGuid(TempFields.SystemId), 'after Get');
    end;

    [Test]
    procedure Insert_IgnoresASystemIdInTheBuffer_UnlessInsertWithSystemId()
    var
        SysFields: Record "Probe Sys Fields";
        Wanted: Guid;
    begin
        Initialize();
        Wanted := CreateGuid();

        SysFields.Id := 2;
        SysFields.SystemId := Wanted;
        SysFields.Insert();
        SysFields.Get(2);
        Assert.AreNotEqual(Wanted, SysFields.SystemId, 'a plain Insert assigns its own SystemId');

        Clear(SysFields);
        SysFields.Id := 3;
        SysFields.SystemId := Wanted;
        SysFields.Insert(false, true);
        SysFields.Get(3);
        Assert.AreEqual(Wanted, SysFields.SystemId, 'InsertWithSystemId keeps it');
    end;

    [Test]
    procedure SystemId_Duplicate_And_ModifyAll_Texts()
    var
        SysFields: Record "Probe Sys Fields";
        Rows: Record "Probe Sys Fields";
        Wanted: Guid;
        Cr: Text[1];
    begin
        Initialize();
        Cr[1] := 13;
        Wanted := CreateGuid();
        SysFields.Id := 3;
        SysFields.SystemId := Wanted;
        SysFields.Insert(false, true);
        Commit();

        Clear(SysFields);
        SysFields.Id := 4;
        SysFields.SystemId := Wanted;
        asserterror SysFields.Insert(false, true);
        Assert.AreEqual('There is already a record in table Probe Sys Fields that has the same values in a unique index for the following fields: System ID=''' + Format(Wanted) + '''', GetLastErrorText(), 'duplicate SystemId');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'code');

        asserterror Rows.ModifyAll(SystemId, CreateGuid());
        Assert.AreEqual('You cannot change the value of the SystemId field.' + Cr + '\' + Cr + '\' + 'Table: Probe Sys Fields', GetLastErrorText(), 'ModifyAll of SystemId');
    end;
}
