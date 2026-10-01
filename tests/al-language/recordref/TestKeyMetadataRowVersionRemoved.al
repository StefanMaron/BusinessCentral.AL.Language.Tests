// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keycount-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keyindex-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: KRV Row (68540), KRV Bank Account Ext (68540) over "Customer Bank Account",
//   KRV Item Ext (68541) over Item, ALT Universal (60000) as a control.
// BC versions: 27.5+
//
// CLAIM: the key list RecordRef.KeyCount()/KeyIndex() walks
//   (1) contains a key declared on SystemRowVersion or SystemModifiedAt, on a table's own key
//       list and in a tableextension over a Base Application table; and
//   (2) does not contain a key declared ObsoleteState = Removed, while a Pending key stays,
//       so a walk calling KeyRef.FieldIndex on every key never reaches the Removed field.
//
// Every "found once" assertion has a control: a table that declares no such key answers 0,
// and the Pending key answers 1, so a pass cannot come from a walk that matches everything
// or from one that hides every obsolete key.
//
// Written by agent stma-auto-4 (AL Runner issues #5135, #5136).

codeunit 68540 "Test Key RowVersion Removed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // How many keys of TableId consist of exactly one field, numbered FieldNo.
    // Calls KeyRef.FieldIndex on every field of every key, so a key whose field cannot be
    // read through a RecordRef fails the walk.
    local procedure CountSingleFieldKeys(TableId: Integer; FieldNo: Integer): Integer
    var
        TableRef: RecordRef;
        KeyReference: KeyRef;
        FieldReference: FieldRef;
        KeyNo: Integer;
        FieldPos: Integer;
        Found: Integer;
    begin
        TableRef.Open(TableId);
        for KeyNo := 1 to TableRef.KeyCount() do begin
            KeyReference := TableRef.KeyIndex(KeyNo);
            for FieldPos := 1 to KeyReference.FieldCount() do
                FieldReference := KeyReference.FieldIndex(FieldPos);
            if KeyReference.FieldCount() = 1 then
                if KeyReference.FieldIndex(1).Number() = FieldNo then
                    Found += 1;
        end;
        TableRef.Close();
        exit(Found);
    end;

    // How many keys of TableId name FieldNo at any position.
    local procedure CountKeysNamingField(TableId: Integer; FieldNo: Integer): Integer
    var
        TableRef: RecordRef;
        KeyReference: KeyRef;
        KeyNo: Integer;
        FieldPos: Integer;
        Found: Integer;
    begin
        TableRef.Open(TableId);
        for KeyNo := 1 to TableRef.KeyCount() do begin
            KeyReference := TableRef.KeyIndex(KeyNo);
            for FieldPos := 1 to KeyReference.FieldCount() do
                if KeyReference.FieldIndex(FieldPos).Number() = FieldNo then
                    Found += 1;
        end;
        TableRef.Close();
        exit(Found);
    end;

    // ── (1) keys on system fields ──────────────────────────────────────────────────────

    [Test]
    procedure TableKey_OnSystemRowVersion_IsEnumerated()
    var
        Row: Record "KRV Row";
    begin
        Assert.AreEqual(1, CountSingleFieldKeys(Database::"KRV Row", Row.FieldNo(SystemRowVersion)),
            'the table''s own key(RowVersionKey; SystemRowVersion) must be in its key list exactly once');
    end;

    [Test]
    procedure TableKey_OnSystemModifiedAt_IsEnumerated()
    var
        Row: Record "KRV Row";
    begin
        Assert.AreEqual(1, CountSingleFieldKeys(Database::"KRV Row", Row.FieldNo(SystemModifiedAt)),
            'the table''s own key(ModifiedAtKey; SystemModifiedAt) must be in its key list exactly once');
    end;

    [Test]
    procedure TableExtensionKey_OnSystemRowVersion_OverBaseAppTable_IsEnumerated()
    var
        BankAccount: Record "Customer Bank Account";
    begin
        Assert.AreEqual(1,
            CountSingleFieldKeys(Database::"Customer Bank Account", BankAccount.FieldNo(SystemRowVersion)),
            'the tableextension''s key(KRVRowVersionKey; SystemRowVersion) must be in Customer Bank Account''s key list exactly once');
    end;

    [Test]
    procedure Control_TableWithoutRowVersionKey_HasNone()
    var
        Universal: Record "ALT Universal";
    begin
        Assert.AreEqual(0, CountSingleFieldKeys(Database::"ALT Universal", Universal.FieldNo(SystemRowVersion)),
            'a table that declares no SystemRowVersion key must not report one');
    end;

    // ── (2) Removed keys are not enumerated ────────────────────────────────────────────

    [Test]
    procedure TableKey_Removed_IsNotCounted_PendingIs()
    var
        TableRef: RecordRef;
    begin
        // PK, RowVersionKey, ModifiedAtKey, PendingKey, LiveKey. RemovedKey is not counted.
        TableRef.Open(Database::"KRV Row");
        Assert.AreEqual(5, TableRef.KeyCount(),
            'KeyCount() must count the five keys that are not ObsoleteState = Removed');
        TableRef.Close();
    end;

    [Test]
    procedure TableKey_Removed_WalkNeverReachesItsField()
    begin
        Assert.AreEqual(0, CountKeysNamingField(Database::"KRV Row", 4),
            'no enumerated key may name the Removed field 4 "Removed Value"');
    end;

    [Test]
    procedure TableKey_Pending_IsStillEnumerated()
    begin
        Assert.AreEqual(1, CountKeysNamingField(Database::"KRV Row", 3),
            'the Pending key on field 3 "Pending Value" must stay in the key list');
    end;

    [Test]
    procedure TableKey_Removed_LastLiveKeyIsAtKeyCount()
    var
        TableRef: RecordRef;
        KeyReference: KeyRef;
    begin
        // LiveKey is declared after RemovedKey, so it sits at position KeyCount() only when
        // the Removed key is skipped by the index as well as by the count.
        TableRef.Open(Database::"KRV Row");
        KeyReference := TableRef.KeyIndex(TableRef.KeyCount());
        Assert.AreEqual(1, KeyReference.FieldCount(), 'LiveKey has one field');
        Assert.AreEqual(2, KeyReference.FieldIndex(1).Number(),
            'KeyIndex(KeyCount()) must be LiveKey on field 2 "Live Value"');
        TableRef.Close();
    end;

    [Test]
    procedure TableExtensionKey_Removed_OverBaseAppTable_IsNotEnumerated()
    begin
        Assert.AreEqual(0, CountKeysNamingField(Database::Item, 68540),
            'the tableextension''s Removed key on field 68540 must not be in Item''s key list');
    end;

    [Test]
    procedure TableExtensionKey_Live_OverBaseAppTable_IsEnumerated()
    begin
        // Control for the test above: the same tableextension's live key is enumerated, so
        // the zero above is not a walk that never sees tableextension keys.
        Assert.AreEqual(1, CountKeysNamingField(Database::Item, 68541),
            'the tableextension''s key(KRVLiveKey; "KRV Live Value") must be in Item''s key list exactly once');
    end;
}
