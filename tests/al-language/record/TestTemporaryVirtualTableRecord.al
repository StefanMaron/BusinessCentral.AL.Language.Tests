// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-virtual-tables
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), Assert (60021), ALTFixtureCleanup (60019)
// BC versions: 27.5+
//
// A `temporary` record of a VIRTUAL system table. The claim under test is that `temporary`
// wins: a `Record "Field" temporary` is an ordinary in-memory table that happens to have the
// Field table's shape, holding exactly the rows AL inserted into it and nothing the platform
// knows about real field metadata. The non-temporary half of the same table keeps answering
// with real metadata, and both facts are asserted here so neither can be satisfied by
// sacrificing the other.
//
// This is not an exotic shape. Base Application report 8621 "Config. Package - Process" builds
// its rule set in a `Record "Field" temporary`, writes the field number into `"No."`, and keys
// its transformation rules off `Format(TempField."No.")` when it reads them back — so if the
// value does not survive the round trip, every rule is stored and looked up under '0'.
//
// Table 2000000041 is used because it is the virtual table with the most interesting shape (a
// two-part primary key, TableNo + "No.", both of which real metadata would fill differently
// from whatever AL writes). Nothing here is specific to it; the rule is about `temporary`.

codeunit 60663 "Test Temporary Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // ── the round trip ───────────────────────────────────────────────────────

    [Test]
    procedure TemporaryField_InsertThenFind_RoundTripsTheValuesALWrote()
    // CLAIM: a temporary Record "Field" hands back exactly what AL put in it — including "No.",
    // which real field metadata would fill with something else entirely.
    var
        TempField: Record "Field" temporary;
    begin
        Initialize();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 7;
        TempField.FieldName := 'MY OWN NAME';
        TempField.Insert();

        TempField.SetRange(TableNo, 60000);
        Assert.IsTrue(TempField.FindSet(), 'the row AL inserted must be findable');
        Assert.AreEqual(60000, TempField.TableNo, 'TableNo must round-trip');
        Assert.AreEqual(7, TempField."No.", '"No." must round-trip');
        Assert.AreEqual('MY OWN NAME', TempField.FieldName, 'FieldName must round-trip');
    end;

    [Test]
    procedure TemporaryField_InsertOneRow_HoldsExactlyThatOneRow()
    // CLAIM, and the load-bearing one: the temporary table contains ONLY AL's row. Real BC does
    // not merge the platform's field metadata into it — table 60000 has 18 declared fields, so
    // a Count of 1 is the difference between "AL's table" and "the metadata table".
    var
        TempField: Record "Field" temporary;
    begin
        Initialize();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 7;
        TempField.Insert();

        TempField.Reset();
        Assert.AreEqual(1, TempField.Count(), 'a temporary Field record must hold only the row AL inserted');
        TempField.SetRange(TableNo, 60000);
        Assert.AreEqual(1, TempField.Count(), 'filtering to the same TableNo must not surface real field metadata');
    end;

    [Test]
    procedure TemporaryField_TwoRowsSameTableNo_StayDistinguishableByNo()
    // CLAIM: the round trip is per-row, not a single value that happens to survive. Two rows
    // under one TableNo keep their own "No." and FieldName.
    var
        TempField: Record "Field" temporary;
    begin
        Initialize();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 3;
        TempField.FieldName := 'THIRD';
        TempField.Insert();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 9;
        TempField.FieldName := 'NINTH';
        TempField.Insert();

        TempField.Reset();
        Assert.AreEqual(2, TempField.Count(), 'both inserted rows must be present');

        TempField.SetRange(TableNo, 60000);
        TempField.SetRange("No.", 9);
        Assert.IsTrue(TempField.FindFirst(), 'the second row must be findable by its own "No."');
        Assert.AreEqual('NINTH', TempField.FieldName, 'each row must keep its own FieldName');

        TempField.SetRange("No.", 3);
        Assert.IsTrue(TempField.FindFirst(), 'the first row must be findable by its own "No."');
        Assert.AreEqual('THIRD', TempField.FieldName, 'each row must keep its own FieldName');
    end;

    [Test]
    procedure TemporaryField_FormatOfNo_IsTheNumberALWrote()
    // CLAIM: the exact expression Base Application report 8621 keys its transformation rules on.
    // Asserted separately from the raw integer because Format() is what the failure surfaced
    // through — the rules were stored and looked up under '0'.
    var
        TempField: Record "Field" temporary;
    begin
        Initialize();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 17;
        TempField.Insert();

        TempField.SetRange(TableNo, 60000);
        Assert.IsTrue(TempField.FindSet(), 'the row AL inserted must be findable');
        Assert.AreEqual('17', Format(TempField."No."), 'Format("No.") must be the number AL wrote');
    end;

    [Test]
    procedure TemporaryField_DeleteAll_EmptiesItWithoutRestoringMetadata()
    // CLAIM, negative direction: emptying the temporary table leaves it empty. If real field
    // metadata were backing it, the rows would come back.
    var
        TempField: Record "Field" temporary;
    begin
        Initialize();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 7;
        TempField.Insert();

        TempField.Reset();
        TempField.DeleteAll();
        Assert.AreEqual(0, TempField.Count(), 'a temporary Field record must be empty after DeleteAll');
        TempField.SetRange(TableNo, 60000);
        Assert.IsFalse(TempField.FindFirst(), 'no real field metadata may reappear after DeleteAll');
    end;

    // ── the non-temporary half must be unaffected ────────────────────────────

    [Test]
    procedure NonTemporaryField_StillReportsRealFieldMetadata()
    // CLAIM, and the guard on every claim above: the NON-temporary Field table still answers
    // with the platform's real metadata. Without this, "a temporary Field record holds only
    // AL's rows" could be satisfied by making the Field table empty for everyone.
    var
        FieldRec: Record "Field";
    begin
        Initialize();

        FieldRec.SetRange(TableNo, 60000);
        FieldRec.SetRange("No.", 1);
        Assert.IsTrue(FieldRec.FindFirst(), 'the non-temporary Field table must report table 60000 field 1');
        Assert.AreEqual('Entry No.', FieldRec.FieldName, 'field 1 of ALT Universal is "Entry No."');
    end;

    [Test]
    procedure NonTemporaryField_ReportsEveryDeclaredFieldOfTheFixtureTable()
    // CLAIM: the non-temporary half reports the whole field set, not one lucky row. ALT Universal
    // declares 18 fields; asserting "at least 18" rather than exactly 18 keeps this honest about
    // the system fields BC adds of its own accord.
    var
        FieldRec: Record "Field";
    begin
        Initialize();

        FieldRec.SetRange(TableNo, 60000);
        Assert.IsTrue(FieldRec.Count() >= 18,
            'the non-temporary Field table must report at least the 18 fields ALT Universal declares');
    end;

    [Test]
    procedure TemporaryAndNonTemporaryField_DoNotShareRows()
    // CLAIM: the two are separate tables. A row inserted into the temporary one is invisible to
    // the non-temporary one, and the non-temporary one's metadata is invisible to the temporary
    // one — asserted in the same test so a fix cannot merge them in either direction.
    var
        TempField: Record "Field" temporary;
        FieldRec: Record "Field";
    begin
        Initialize();

        TempField.Init();
        TempField.TableNo := 60000;
        TempField."No." := 99001;
        TempField.FieldName := 'NOT REAL';
        TempField.Insert();

        FieldRec.SetRange(TableNo, 60000);
        FieldRec.SetRange("No.", 99001);
        Assert.IsFalse(FieldRec.FindFirst(),
            'a row inserted into a temporary Field record must not appear in the real Field table');

        TempField.Reset();
        TempField.SetRange(TableNo, 60000);
        TempField.SetRange("No.", 1);
        Assert.IsFalse(TempField.FindFirst(),
            'real field metadata must not appear in a temporary Field record');
    end;
}
