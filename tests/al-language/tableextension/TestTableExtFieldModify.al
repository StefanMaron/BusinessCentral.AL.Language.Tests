// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-caption-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Modified (60506) and ALT Modified Ext (60499), the tableextension that
//   changes field 10's Caption through modify(...), leaves field 11 alone, and adds field
//   50000.
// BC versions: 27.0+
//
// CLAIM (the file's subject): a tableextension's `modify(<field>)` block CHANGES the existing
// field's declared properties on the extended table, and the changed value is what AL reads
// back. The corpus already pins what a tableextension ADDS — columns
// (TestTableExtCrossApp), keys and InitValue (TestTableExtKeysAndInitValue), OnValidate
// (TestTableExtFieldTestPageControl) — but nothing yet asks whether modify(...) does
// anything at all.
//
// The distinction matters because the two halves of a tableextension are not the same
// mechanism underneath: a field it ADDS is folded into the base table's own compiled
// metadata, while a property it MODIFIES is carried separately as a delta against that
// table. A consumer can implement the first and not the second, and every existing
// tableextension test in this corpus would still pass. So each test below is paired with a
// CONTROL ARM — an unmodified field of the same table, or the added field — which fails in
// the opposite direction if captions are simply broken.
//
// Caption is the property under test because AL permits very few properties in a table
// field's modify(...) at all — NotBlank, MinValue, MaxValue, Editable, DataClassification
// and most others are rejected at compile time (AL0246 / AL0294) in this position — and
// Caption is among the few that is both permitted and readable from AL.
//
// Written by agent stma-auto-2.

codeunit 60500 "TableExt Field Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ── modify(...) changes the caption, via Record.FieldCaption ─────────────────────────

    [Test]
    procedure TableExtModify_FieldCaption_AnswersTheExtensionsCaption()
    // CLAIM: field 10 declares Caption = 'Original Overridden Caption' on the table and the
    // tableextension's modify(...) sets 'Extension Overridden Caption'. FieldCaption answers
    // the EXTENSION's value.
    var
        Modified: Record "ALT Modified";
    begin
        Assert.AreEqual(
          'Extension Overridden Caption', Modified.FieldCaption("Overridden Field"),
          'FieldCaption must answer the Caption the tableextension modify(...) declared, not the table''s own');
    end;

    [Test]
    procedure TableExtModify_FieldCaption_LeavesAnUnmodifiedFieldAlone()
    // CONTROL for the test above. Field 11 is declared by the same table and is NOT named by
    // any modify(...) block, so it must still answer the TABLE's caption. Without this arm a
    // consumer that returned the extension's caption for every field of the table would pass
    // the test above.
    var
        Modified: Record "ALT Modified";
    begin
        Assert.AreEqual(
          'Original Untouched Caption', Modified.FieldCaption("Untouched Field"),
          'a field no modify(...) names must keep the Caption its own table declared');
    end;

    [Test]
    procedure TableExtModify_FieldCaption_AddedFieldKeepsItsOwnCaption()
    // SECOND CONTROL: the field the SAME tableextension adds. An added field and a modified
    // field reach the table by different routes, so this arm distinguishes "the extension is
    // being read at all" from "the modify(...) half of it is being read".
    var
        Modified: Record "ALT Modified";
    begin
        Assert.AreEqual(
          'Added Field Caption', Modified.FieldCaption("Added Field"),
          'a field the tableextension ADDS must carry the Caption the extension declared for it');
    end;

    // ── The same claim through RecordRef/FieldRef ────────────────────────────────────────

    [Test]
    procedure TableExtModify_FieldRefCaption_AnswersTheExtensionsCaption()
    // CLAIM: the change is on the table's METADATA, not a property of the strongly-typed
    // Record wrapper — so the late-bound read answers it too. FieldRef.Caption reaches the
    // field metadata by a different path than Record.FieldCaption above.
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(60506);
        FldRef := RecRef.Field(10);
        Assert.AreEqual(
          'Extension Overridden Caption', FldRef.Caption(),
          'FieldRef.Caption must answer the Caption the tableextension modify(...) declared');
    end;

    [Test]
    procedure TableExtModify_FieldRefCaption_LeavesAnUnmodifiedFieldAlone()
    // CONTROL for the FieldRef arm, same role as the Record control above.
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(60506);
        FldRef := RecRef.Field(11);
        Assert.AreEqual(
          'Original Untouched Caption', FldRef.Caption(),
          'FieldRef.Caption on a field no modify(...) names must keep the table''s own Caption');
    end;

    // ── modify(...) changes only the property it names ───────────────────────────────────

    [Test]
    procedure TableExtModify_LeavesTheFieldsNameAndTypeIntact()
    // CLAIM: modify(...) changes the properties it lists and nothing else. The field keeps
    // its name, its number and its type — so the caption change above is a property change,
    // not the field being replaced. Asserted through FieldName (the name is NOT the caption
    // here, which is what makes this readable at all) and a round-tripped value.
    var
        Modified: Record "ALT Modified";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Assert.AreEqual(
          'Overridden Field', Modified.FieldName("Overridden Field"),
          'modify(...) must not change the field''s NAME');

        RecRef.Open(60506);
        FldRef := RecRef.Field(10);
        FldRef.Value := 'still a Text field';
        Assert.AreEqual(
          'still a Text field', Format(FldRef.Value),
          'modify(...) must leave the field''s TYPE assignable exactly as the table declared it');
    end;
}
