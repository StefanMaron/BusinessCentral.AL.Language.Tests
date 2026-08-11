// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-importstream-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-insert-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-mediaid-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Media (60980)
// BC versions: 27.5+
//
// Companion of StefanMaron/BusinessCentral.AL.Runner#1773, which reports that AL Runner's
// MediaSet.ImportStream returns a non-null MediaId whose membership is then invisible to
// Count()/Item() after Modify()+Get() — while the single-value Media field (used here as
// the control, MediaSetPersistence_Media_ImportStream_ModifyThenGet_HasValueTrue) already
// round-trips correctly. These tests pin the correct (real BC) behavior of both field types
// across a write/re-read cycle, including the differential between MediaSet's returned
// import id (the set's own container id, same value MediaId() returns) and the per-item id
// Item() returns.
codeunit 60951 "Test MediaSet Persistence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Control: Media (single) ─────────────────────────────────────────────────────

    [Test]
    procedure Media_ImportStream_ModifyThenGet_HasValueTrue()
    // CLAIM: a Media field's ImportStream()'d content survives Modify()+Get() — the
    // control case MediaSet is compared against.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'M1';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('picture-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Picture.ImportStream(InStr, 'a picture');
        Rec.Modify();

        Assert.IsFalse(IsNullGuid(MediaId), 'Media.ImportStream must return a non-empty MediaId');

        Rec.Get('M1');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Media field must have a value after Modify()+Get()');
    end;

    // ── Core regression: MediaSet.ImportStream ──────────────────────────────────────

    [Test]
    procedure MediaSet_Count_NeverTouched_ReturnsZero()
    // CLAIM: Count() is 0 for a MediaSet field nothing has ever been added to.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Code := 'C1';
        Rec.Insert();

        Assert.AreEqual(0, Rec.Images.Count(), 'Count() must be 0 for an untouched MediaSet field');
    end;

    [Test]
    procedure MediaSet_ImportStream_ModifyThenGet_CountIsOne()
    // CLAIM: MediaSet.ImportStream()'s membership survives Modify()+Get() through the SAME
    // record variable. This is the literal AL Runner#1773 repro.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS1';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('sample-image-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Images.ImportStream(InStr, 'sample image');
        Rec.Modify();

        Assert.IsFalse(IsNullGuid(MediaId), 'MediaSet.ImportStream must return a non-empty id');

        Rec.Get('MS1');
        Assert.AreEqual(1, Rec.Images.Count(), 'Count() must be 1 after Modify()+Get()');
    end;

    [Test]
    procedure MediaSet_ImportStream_ModifyThenGetSecondVariable_CountIsOne()
    // CLAIM: same claim as above, but the re-read happens through a SEPARATE AL record
    // variable of the same row, not just the one that performed the import.
    var
        Rec1: Record "ALT Media";
        Rec2: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec1.Code := 'MS2';
        Rec1.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('second-variable-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec1.Images.ImportStream(InStr, 'second variable');
        Rec1.Modify();

        Rec2.Get('MS2');
        Assert.AreEqual(1, Rec2.Images.Count(), 'Count() must be 1 via a second record variable pointed at the same row');
        Assert.AreEqual(MediaId, Rec2.Images.MediaId(), 'MediaId() via the second record variable must equal ImportStream()''s returned id');
    end;

    [Test]
    procedure MediaSet_ImportStream_MediaId_EqualsReturnedId()
    // CLAIM: MediaSet.MediaId() returns the SAME value ImportStream() returned — both read
    // the field's own container id.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS3';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('id-check-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Images.ImportStream(InStr, 'id check');
        Rec.Modify();

        Rec.Get('MS3');
        Assert.AreEqual(MediaId, Rec.Images.MediaId(), 'MediaId() must equal the id ImportStream() returned');
    end;

    [Test]
    procedure MediaSet_ImportStream_Item_DiffersFromMediaId()
    // CLAIM: Item(1) — the individual imported media object's own id — is a DIFFERENT guid
    // from MediaId()/ImportStream()'s return value, which identifies the set container, not
    // any one item in it.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        ReturnedId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS4';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('item-vs-set-bytes');
        TempBlob.CreateInStream(InStr);
        ReturnedId := Rec.Images.ImportStream(InStr, 'item vs set');
        Rec.Modify();

        Rec.Get('MS4');
        Assert.AreEqual(1, Rec.Images.Count(), 'Count() must be 1');
        Assert.AreNotEqual(ReturnedId, Rec.Images.Item(1), 'Item(1) (the media object id) must differ from ImportStream()''s returned set id');
        Assert.IsFalse(IsNullGuid(Rec.Images.Item(1)), 'Item(1) must be a real, non-empty id');
    end;

    [Test]
    procedure MediaSet_ImportStream_Content_RoundTripsThroughTenantMedia()
    // CLAIM: the bytes passed to ImportStream() are retrievable afterwards by looking up
    // Item(1)'s id in the "Tenant Media" system table — the documented way to read a
    // MediaSet member's content back out.
    var
        Rec: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        Content: Text;
    begin
        Initialize();

        Rec.Code := 'MS5';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('round-trip-bytes');
        TempBlob.CreateInStream(InStr);
        Rec.Images.ImportStream(InStr, 'round trip');
        Rec.Modify();

        Rec.Get('MS5');
        Assert.IsTrue(TenantMedia.Get(Rec.Images.Item(1)), 'Tenant Media row for the imported item must exist');
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(InStr);
        InStr.ReadText(Content);
        Assert.AreEqual('round-trip-bytes', Content, 'Content read back from Tenant Media must match what was imported');
    end;

    [Test]
    procedure MediaSet_Remove_ModifyThenGet_CountIsZero()
    // CLAIM: Remove()'s effect on Count() survives Modify()+Get(), same as Insert()'s does.
    var
        Rec: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'MS6';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('to-be-removed-bytes');
        TempBlob.CreateInStream(InStr);
        Rec.Images.ImportStream(InStr, 'to be removed');
        Rec.Modify();

        Rec.Get('MS6');
        MediaId := Rec.Images.Item(1);
        Assert.IsTrue(Rec.Images.Remove(MediaId), 'Remove() must return true for an id that is really in the set');
        Rec.Modify();

        Rec.Get('MS6');
        Assert.AreEqual(0, Rec.Images.Count(), 'Count() must be 0 after Remove()+Modify()+Get()');
    end;

    [Test]
    procedure MediaSet_Remove_NeverInserted_ReturnsFalse()
    // CLAIM: Remove() returns false (negative case) for an id that was never added.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Code := 'MS7';
        Rec.Insert();

        Assert.IsFalse(Rec.Images.Remove(CreateGuid()), 'Remove() must return false for an id never inserted');
    end;

    // ── Temporary record variant ─────────────────────────────────────────────────────

    [Test]
    procedure MediaSet_Temporary_ImportStream_Get_CountIsOne()
    // CLAIM: MediaSet membership on a `temporary` record survives its own Modify()+Get()
    // cycle against the record's private in-memory buffer, same as a database-backed row.
    var
        Rec: Record "ALT Media" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        MediaId: Guid;
    begin
        Initialize();

        Rec.Code := 'TMP1';
        Rec.Insert();
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('temp-bytes');
        TempBlob.CreateInStream(InStr);
        MediaId := Rec.Images.ImportStream(InStr, 'temp record');
        Rec.Modify();

        Assert.IsFalse(IsNullGuid(MediaId), 'MediaSet.ImportStream must return a non-empty id on a temporary record');

        Rec.Get('TMP1');
        Assert.AreEqual(1, Rec.Images.Count(), 'Count() must be 1 after Modify()+Get() on a temporary record');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
