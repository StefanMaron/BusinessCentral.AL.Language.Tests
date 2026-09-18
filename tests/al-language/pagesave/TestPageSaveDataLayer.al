// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Save Row (60560), ALT Page Save Card (60561); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: a row saved by a PAGE gets the same data-layer treatment as a row saved by
/// Record.Insert / Record.Modify. The AutoIncrement key is assigned, and SystemCreatedAt,
/// SystemCreatedBy, SystemModifiedAt and SystemModifiedBy are stamped -- by the platform, on
/// the page's own save path, with no AL anywhere assigning any of them.
///
/// The corpus already pins the two halves separately and neither covers this. `pageupdate`
/// (codeunit 60496) drives CurrPage.Update() and asserts TRIGGERS -- it never reads a stored
/// field. `record/TestBCSystemFieldContracts.al` (codeunit 60172) and
/// `record/TestAutoIncrementContracts.al` (codeunit 60201) read exactly these fields but only
/// ever through Record.Insert / Record.Modify -- neither file names TestPage at all. The
/// intersection, a system field or an AutoIncrement value on a row a PAGE saved, is what this
/// file measures.
///
/// WHY IT IS WORTH MEASURING: the page save is a different code path in the platform from the
/// AL record API, and everything read here is contributed by the data layer underneath both.
/// A platform that put the AutoIncrement assignment or the system-field stamp on the AL entry
/// point rather than in the data layer would answer correctly for Record.Insert and leave a
/// page-saved row with Entry No. = 0 and 0DT / null-guid system fields -- observably wrong, and
/// invisible to every test that writes through Record.Insert.
///
/// EACH TEST CARRIES ITS OWN CONTROL:
///
///   1. Every positive read is paired with a negative one -- a filter no row satisfies must
///      find nothing, so "the row exists" cannot be satisfied by a Get that answers true for
///      any key.
///   2. The record-API arm (RecordInsert_*) asserts the SAME values through Record.Insert. It
///      is what makes the claim "the data layer does this, whichever route reached it" rather
///      than "pages do something special".
///   3. The modify arm asserts that a page-driven Modify moves SystemModifiedAt forward AND
///      leaves SystemCreatedAt/SystemCreatedBy exactly as the insert left them. An
///      implementation that re-ran the INSERT stamp on the page's modify path would satisfy
///      "SystemModifiedAt is set" and fail here, which is the point of asserting both.
///
/// The AutoIncrement readings are asserted as "> 0" and as distinct between two rows, not as a
/// literal: which value the sequence is at is a property of the tier, not of the platform rule.
/// </summary>
codeunit 60562 "ALT Page Save Data Layer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Every row is cleared first, so a row an earlier test left behind cannot be the row a
    // later one finds through its Description filter.
    local procedure Initialize()
    var
        Row: Record "ALT Page Save Row";
    begin
        Row.Reset();
        Row.DeleteAll();
    end;

    local procedure SavedRow(var Row: Record "ALT Page Save Row"; Description: Text[50]): Boolean
    begin
        Row.Reset();
        Row.SetRange(Description, Description);
        exit(Row.FindFirst());
    end;

    [Test]
    procedure PageSave_NewRow_GetsAnAutoIncrementEntryNo()
    // CLAIM: a new row saved by CurrPage.Update() from a field's OnValidate carries a positive
    // AutoIncrement key. Nothing in the page or the test assigns "Entry No.", so a positive
    // value can only have come from the platform's sequence.
    var
        Row: Record "ALT Page Save Row";
        Card: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.DescriptionField.SetValue('PSAVE-AI-1');

        Assert.IsTrue(SavedRow(Row, 'PSAVE-AI-1'),
            'control arm: CurrPage.Update() must have inserted the row');
        Assert.IsTrue(Row."Entry No." > 0,
            'a row saved by a page must get a positive AutoIncrement Entry No. from the platform');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-NO-SUCH-ROW'),
            'a Description no test wrote must match no row');

        Card.Close();
    end;

    [Test]
    procedure PageSave_TwoNewRows_GetDistinctEntryNos()
    // CLAIM: the sequence advances per page-saved row, so two rows saved through the page do
    // not collide on the key. A platform that left both at the default would pass the
    // "> 0" arm only by accident and fails here.
    var
        Row: Record "ALT Page Save Row";
        First: Integer;
        Second: Integer;
        Card: TestPage "ALT Page Save Card";
        SecondCard: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.DescriptionField.SetValue('PSAVE-AI-A');
        Assert.IsTrue(SavedRow(Row, 'PSAVE-AI-A'), 'control arm: the first page save must have inserted a row');
        First := Row."Entry No.";
        Card.Close();

        SecondCard.OpenNew();
        SecondCard.DescriptionField.SetValue('PSAVE-AI-B');
        Assert.IsTrue(SavedRow(Row, 'PSAVE-AI-B'), 'control arm: the second page save must have inserted a row');
        Second := Row."Entry No.";
        SecondCard.Close();

        Assert.IsTrue(First > 0, 'the first page-saved row must have a positive Entry No.');
        Assert.IsTrue(Second > First,
            'the second page-saved row must get a later sequence value than the first');
    end;

    [Test]
    procedure PageSave_NewRow_StampsAllFourSystemFields()
    // CLAIM: a page-saved new row has SystemCreatedAt and SystemModifiedAt set to a real
    // instant and SystemCreatedBy / SystemModifiedBy set to a non-null user GUID -- the same
    // four values Record.Insert produces (asserted by the control arm below).
    var
        Row: Record "ALT Page Save Row";
        Card: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.DescriptionField.SetValue('PSAVE-SYS-1');

        Assert.IsTrue(SavedRow(Row, 'PSAVE-SYS-1'),
            'control arm: CurrPage.Update() must have inserted the row');

        Assert.AreNotEqual(0DT, Row.SystemCreatedAt,
            'SystemCreatedAt must be stamped on a row saved by a page');
        Assert.AreNotEqual(0DT, Row.SystemModifiedAt,
            'SystemModifiedAt must be stamped on a row saved by a page');
        Assert.IsFalse(IsNullGuid(Row.SystemCreatedBy),
            'SystemCreatedBy must be a non-null user GUID on a row saved by a page');
        Assert.IsFalse(IsNullGuid(Row.SystemModifiedBy),
            'SystemModifiedBy must be a non-null user GUID on a row saved by a page');
        Assert.IsTrue(Row.SystemCreatedAt <= Row.SystemModifiedAt,
            'SystemCreatedAt must be <= SystemModifiedAt on a row saved by a page');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-NO-SUCH-ROW'),
            'a Description no test wrote must match no row');

        Card.Close();
    end;

    [Test]
    procedure PageSave_ModifiedRow_MovesModifiedStampAndLeavesCreatedStamp()
    // CLAIM: a page-driven Modify -- CurrPage.Update() on a row that already exists -- moves
    // SystemModifiedAt forward and leaves SystemCreatedAt / SystemCreatedBy exactly as the
    // insert left them. Asserted as a pair on purpose: an implementation re-running the INSERT
    // stamp on the modify path satisfies the first half and fails the second.
    var
        Row: Record "ALT Page Save Row";
        CreatedAt: DateTime;
        CreatedBy: Guid;
        ModifiedAtBefore: DateTime;
        EntryNo: Integer;
        Card: TestPage "ALT Page Save Card";
    begin
        Initialize();

        Row.Init();
        Row."Entry No." := 0;
        Row.Description := 'PSAVE-MOD-BEFORE';
        Row.Insert();

        Assert.IsTrue(SavedRow(Row, 'PSAVE-MOD-BEFORE'), 'control arm: the seed row must exist');
        EntryNo := Row."Entry No.";
        CreatedAt := Row.SystemCreatedAt;
        CreatedBy := Row.SystemCreatedBy;
        ModifiedAtBefore := Row.SystemModifiedAt;

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.DescriptionField.SetValue('PSAVE-MOD-AFTER');
        Card.Close();

        Assert.IsTrue(Row.Get(EntryNo), 'control arm: the row must still exist under its own key');
        Assert.AreEqual('PSAVE-MOD-AFTER', Row.Description,
            'control arm: the page save must have written the new value');

        Assert.IsTrue(Row.SystemModifiedAt >= ModifiedAtBefore,
            'SystemModifiedAt must be >= its previous value after a page-driven Modify');
        Assert.AreNotEqual(0DT, Row.SystemModifiedAt,
            'SystemModifiedAt must be a real instant after a page-driven Modify');
        Assert.AreEqual(CreatedAt, Row.SystemCreatedAt,
            'SystemCreatedAt must NOT change on a page-driven Modify -- it records creation');
        Assert.AreEqual(Format(CreatedBy), Format(Row.SystemCreatedBy),
            'SystemCreatedBy must NOT change on a page-driven Modify -- it records the creator');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-MOD-BEFORE'),
            'the pre-edit Description must match no row after the page save');
    end;

    [Test]
    procedure RecordInsert_NewRow_GetsTheSameDataLayerTreatment()
    // CLAIM: the control arm. Record.Insert on the same table produces a positive AutoIncrement
    // key and the same four stamped system fields, so the page arms above are measuring one
    // data-layer rule reached by a second route -- not something pages do on their own.
    var
        Row: Record "ALT Page Save Row";
    begin
        Initialize();

        Row.Init();
        Row."Entry No." := 0;
        Row.Description := 'PSAVE-REC-1';
        Row.Insert();

        Assert.IsTrue(SavedRow(Row, 'PSAVE-REC-1'), 'control arm: Record.Insert must have inserted the row');
        Assert.IsTrue(Row."Entry No." > 0,
            'a row inserted by Record.Insert must get a positive AutoIncrement Entry No.');
        Assert.AreNotEqual(0DT, Row.SystemCreatedAt,
            'SystemCreatedAt must be stamped on a row inserted by Record.Insert');
        Assert.AreNotEqual(0DT, Row.SystemModifiedAt,
            'SystemModifiedAt must be stamped on a row inserted by Record.Insert');
        Assert.IsFalse(IsNullGuid(Row.SystemCreatedBy),
            'SystemCreatedBy must be a non-null user GUID on a row inserted by Record.Insert');
        Assert.IsFalse(IsNullGuid(Row.SystemModifiedBy),
            'SystemModifiedBy must be a non-null user GUID on a row inserted by Record.Insert');

        Assert.IsFalse(SavedRow(Row, 'PSAVE-NO-SUCH-ROW'),
            'a Description no test wrote must match no row');
    end;
}
