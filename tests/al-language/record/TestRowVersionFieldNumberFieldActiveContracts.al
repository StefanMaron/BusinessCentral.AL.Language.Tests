// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldactive-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68950, codeunit 68951
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - SystemRowVersion: FieldNo(SystemRowVersion) is 0; RecordRef.Field(0) is a BigInteger field named "timestamp" with
//    Number() 0; RecordRef.FieldExist(0) is false and the field is not in the FieldIndex list.
//  - FieldCount counts the enabled fields of the table and none of the system fields: for fields Id, Txt, Dis (Enabled = false)
//    and Obs (ObsoleteState = Pending) it is 3 (a disabled field is not counted and not listed). FieldIndex(FieldCount + 1 .. + 5) are the
//    system fields $systemId (2000000000), SystemCreatedAt (2000000001), SystemCreatedBy (2000000002), SystemModifiedAt
//    (2000000003) and SystemModifiedBy (2000000004); FieldIndex past them raises "Index out of bounds." / IndexOutOfBounds.
//  - FieldExist is false for the disabled field and true for the obsolete (Pending) one; FieldActive answers false for the disabled
//    field, true for an enabled and for a Pending one.
// BC versions: 27.5

table 68950 "Probe RowVer Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Dis; Integer) { Enabled = false; }
        field(4; Obs; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'probe';
            ObsoleteTag = '1.0';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68951 "Probe RowVer FieldActive"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SystemRowVersion_IsFieldZero_ButNotInTheFieldList()
    var
        RvRec: Record "Probe RowVer Table";
        RvRef: RecordRef;
        FldRef: FieldRef;
        Index: Integer;
        Names: Text;
    begin
        RvRec.DeleteAll();
        RvRec.Id := 1;
        RvRec.Insert();
        RvRef.GetTable(RvRec);

        Assert.AreEqual(0, RvRec.FieldNo(SystemRowVersion), 'FieldNo');
        FldRef := RvRef.Field(RvRec.FieldNo(SystemRowVersion));
        Assert.AreEqual('timestamp', FldRef.Name(), 'name');
        Assert.AreEqual(0, FldRef.Number(), 'number');
        Assert.AreEqual(FieldType::BigInteger, FldRef.Type(), 'type');
        Assert.IsFalse(RvRef.FieldExist(0), 'FieldExist(0)');

        Assert.AreEqual(3, RvRef.FieldCount(), 'FieldCount: Id, Txt, Obs');
        for Index := 1 to RvRef.FieldCount() + 5 do begin
            FldRef := RvRef.FieldIndex(Index);
            Names += FldRef.Name() + '#' + Format(FldRef.Number()) + ' ';
        end;
        Assert.AreEqual('Id#1 Txt#2 Obs#4 $systemId#2000000000 SystemCreatedAt#2000000001 SystemCreatedBy#2000000002 SystemModifiedAt#2000000003 SystemModifiedBy#2000000004 ', Names, 'index list');
        Assert.AreEqual(2000000003, RvRec.FieldNo(SystemModifiedAt), 'SystemModifiedAt');

        asserterror FldRef := RvRef.FieldIndex(RvRef.FieldCount() + 40);
        Assert.AreEqual('Index out of bounds.', GetLastErrorText(), 'text');
        Assert.AreEqual('IndexOutOfBounds', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure FieldActive_FalseForADisabledField_TrueForPendingObsolete()
    var
        RvRec: Record "Probe RowVer Table";
        RvRef: RecordRef;
    begin
        RvRef.GetTable(RvRec);

        Assert.IsTrue(RvRec.FieldActive(Txt), 'enabled');
        Assert.IsFalse(RvRec.FieldActive(Dis), 'Enabled = false');
        Assert.IsTrue(RvRec.FieldActive(Obs), 'ObsoleteState = Pending');
        Assert.IsFalse(RvRef.FieldExist(3), 'FieldExist of the disabled field');
        Assert.IsTrue(RvRef.FieldExist(4), 'FieldExist of the Pending one');
    end;
}
