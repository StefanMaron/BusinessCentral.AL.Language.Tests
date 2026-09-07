// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-partial-records
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-addloadfields-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-arefieldsloaded-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), ALT Keyed (60006); shared Assert (60021)
// BC versions: 27.0+
//
// WHAT THIS MEASURES, AND WHY IT IS NOT ALREADY COVERED.
//
// Partial records are pinned in three places today, and all three assert only the EASY half
// of the contract -- that a field you DID ask for is readable afterwards:
//
//   cu 60058 Record_LoadFields_FieldsAreAvailable      SetLoadFields(X) then read X
//   cu 60058 Record_AreFieldsLoaded_ReturnsTrueWhenLoaded   ... AreFieldsLoaded(X) is true
//   cu 60058 Record_SetLoadFields_LimitsLoadedFields   despite its name, also only reads X
//
// None of them touches a field that was NOT requested, and none establishes what the
// load set actually ends up containing. So the interesting half of partial records --
// which fields BC silently ADDS to your request, and what reading an omitted field does --
// is unmeasured. This codeunit measures that half. It does not modify or contradict the
// three tests above; every one of them stays green and stays where it is.
//
// The five claims below are each a specific value that a plausible-but-wrong implementation
// gets wrong, which is the bar in CLAUDE.md's test contract:
//
//   1. SetLoadFields() with NO arguments is not a no-op and not an error -- it RESETS to
//      the table's default (full) load set. A reader would reasonably guess "load nothing".
//   2. AreFieldsLoaded is FALSE on a record that has never been fetched -- even for a field
//      nobody excluded, and even for the primary key. "Loaded" is a statement about a
//      fetched buffer, not about the field list.
//   3. Reading a field that was deliberately excluded does NOT return the type default.
//      BC fetches it on demand (JIT load), so the omitted field still reads its true
//      stored value. This is the single most consequential fact about partial records:
//      SetLoadFields is a performance hint, never a data filter, and code that treated an
//      omitted field as blank would be silently wrong against real BC.
//   4. Fields of the CURRENT SORT KEY are force-added to the load set even when not asked
//      for -- so the same SetLoadFields call yields a different AreFieldsLoaded answer
//      depending on SetCurrentKey.
//   5. Fields used in an ACTIVE FILTER are likewise force-added.
//
// Claims 4 and 5 are the two that a from-scratch implementation is most likely to miss,
// because nothing in the AL source of the test says those fields are wanted -- the platform
// adds them because it needs them to sort and to filter the rows it is about to return.
//
// Negative direction: SetLoadFields with a field number that belongs to no field must
// throw rather than be ignored (Record_SetLoadFields_UnknownFieldNo_Throws).

codeunit 60775 "Test Record Partial Load"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── SetLoadFields() with no arguments resets to the full default load set ────

    [Test]
    procedure PartialLoad_SetLoadFieldsNoArgs_ResetsToFullLoad()
    // CLAIM: SetLoadFields() called with zero arguments does not select "no fields" and does
    // not error -- it restores the table's DEFAULT field load info, i.e. a full load. After
    // it, a field excluded by an earlier narrowing call reports as loaded again.
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 500;
        Rec."Integer Field" := 11;
        Rec."Text Field" := 'reset-me';
        Rec.Insert();

        Clear(Rec);
        Rec.SetLoadFields(Rec."Integer Field");
        Rec.Get(500);
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Precondition: Text Field must be UNLOADED while only Integer Field was requested');

        // Widen back to the default load set, then re-fetch.
        Rec.SetLoadFields();
        Rec.Get(500);

        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'SetLoadFields() with no arguments must reset to the DEFAULT (full) load set, making Text Field loaded again');
        Assert.AreEqual(
          'reset-me', Rec."Text Field",
          'After SetLoadFields() reset, Text Field must read its stored value');
    end;

    // ── AreFieldsLoaded is false before the record has been fetched ──────────────

    [Test]
    procedure PartialLoad_AreFieldsLoaded_BeforeFetch_ReturnsFalse()
    // CLAIM: AreFieldsLoaded answers about a FETCHED buffer, not about the requested field
    // list. On a record that has never been read, it is false -- even for the primary key,
    // and even immediately after SetLoadFields named the very field being asked about.
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        Rec."Entry No." := 501;
        Rec."Integer Field" := 22;
        Rec.Insert();

        Clear(Rec);
        Rec.SetLoadFields(Rec."Integer Field");

        // No Get / Find yet: there is no record buffer to be loaded.
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Integer Field"),
          'AreFieldsLoaded must be FALSE before any fetch, even for the field just passed to SetLoadFields');
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Entry No."),
          'AreFieldsLoaded must be FALSE before any fetch, even for the primary key field');

        // ... and true for that field once a fetch has actually happened.
        Rec.Get(501);
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Integer Field"),
          'AreFieldsLoaded must be TRUE for the requested field after the record is fetched');
    end;

    // ── An omitted field is JIT-loaded on access, not blanked ────────────────────

    [Test]
    procedure PartialLoad_ReadOmittedField_JitLoadsRealValue()
    // CLAIM: SetLoadFields is a performance hint, never a data filter. Reading a field that
    // was deliberately left out of the load set returns its REAL stored value -- BC fetches
    // it on demand -- and the read itself flips that field to loaded. The wrong answer here
    // is the type default (0 / '').
    var
        Rec: Record "ALT Universal";
        ObservedText: Text[100];
        ObservedDecimal: Decimal;
    begin
        Initialize();

        Rec."Entry No." := 502;
        Rec."Integer Field" := 33;
        Rec."Text Field" := 'jit-loaded';
        Rec."Decimal Field" := 12.5;
        Rec.Insert();

        Clear(Rec);
        Rec.SetLoadFields(Rec."Integer Field");
        Rec.Get(502);

        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'Precondition: Text Field must start out UNLOADED');

        ObservedText := Rec."Text Field";
        ObservedDecimal := Rec."Decimal Field";

        Assert.AreEqual(
          'jit-loaded', ObservedText,
          'Reading an omitted Text field must JIT-load its stored value, NOT return the empty default');
        Assert.AreEqual(
          12.5, ObservedDecimal,
          'Reading an omitted Decimal field must JIT-load its stored value, NOT return 0');
        Assert.AreEqual(
          33, Rec."Integer Field",
          'The explicitly requested field must still hold its stored value');
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec."Text Field"),
          'After the JIT load, Text Field must report as loaded');
    end;

    // ── The current sort key's fields are force-added to the load set ────────────

    [Test]
    procedure PartialLoad_CurrentKeyFields_AreForceLoaded()
    // CLAIM: the platform adds the fields of the CURRENT SORT KEY to the load set, because
    // it needs them to order the rows. So an identical SetLoadFields call answers
    // AreFieldsLoaded differently depending on SetCurrentKey -- nothing in the AL asks for
    // "Amount", yet sorting by it makes it loaded.
    var
        Rec: Record "ALT Keyed";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Name := 'alpha';
        Rec.Code := 'A1';
        Rec.Amount := 75.0;
        Rec.Insert();

        // Sorted by the primary key: Amount is neither requested nor part of the sort.
        Clear(Rec);
        Rec.SetCurrentKey("Entry No.");
        Rec.SetLoadFields(Rec.Name);
        Rec.FindFirst();
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec.Amount),
          'Under key PK, Amount is neither requested nor sorted on, so it must be UNLOADED');

        // Same SetLoadFields call, now sorted by Amount (key "Key2").
        Clear(Rec);
        Rec.SetCurrentKey(Amount);
        Rec.SetLoadFields(Rec.Name);
        Rec.FindFirst();
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec.Amount),
          'Under key Amount, the sort field must be force-added to the load set even though only Name was requested');
        Assert.AreEqual(
          75.0, Rec.Amount,
          'The force-loaded sort field must hold its stored value');
    end;

    // ── Fields used in an active filter are force-added to the load set ──────────

    [Test]
    procedure PartialLoad_FilteredFields_AreForceLoaded()
    // CLAIM: a field carrying an active filter is force-added to the load set, because the
    // platform needs it to decide which rows qualify. Only "Name" is requested, yet filtering
    // on "Code" makes Code loaded too.
    var
        Rec: Record "ALT Keyed";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec.Name := 'alpha';
        Rec.Code := 'A1';
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Name := 'beta';
        Rec.Code := 'B2';
        Rec.Insert();

        // No filter on Code: it is not requested, so it stays unloaded.
        Clear(Rec);
        Rec.SetLoadFields(Rec.Name);
        Rec.SetRange("Entry No.", 2);
        Rec.FindFirst();
        Assert.IsFalse(
          Rec.AreFieldsLoaded(Rec.Code),
          'Without a filter on Code, an unrequested Code must be UNLOADED');

        // Filter on Code: the platform must load it to evaluate the filter.
        Clear(Rec);
        Rec.SetLoadFields(Rec.Name);
        Rec.SetRange(Code, 'B2');
        Rec.FindFirst();
        Assert.IsTrue(
          Rec.AreFieldsLoaded(Rec.Code),
          'A field carrying an active filter must be force-added to the load set');
        Assert.AreEqual(
          'B2', Rec.Code,
          'The force-loaded filter field must hold the stored value that matched the filter');
        Assert.AreEqual(
          2, Rec."Entry No.",
          'The filter must still select the intended row');
    end;

    // ── Negative: an unknown field number is rejected, not ignored ───────────────

    [Test]
    procedure PartialLoad_SetLoadFields_UnknownFieldNo_Throws()
    // CLAIM: SetLoadFields validates the field numbers it is given. A number belonging to no
    // field on the table must raise a runtime error rather than being silently dropped --
    // silently ignoring it would leave the caller believing a field was selected when the
    // load set never mentioned it.
    var
        RecRef: RecordRef;
    begin
        Initialize();

        // Field 9999 does not exist on ALT Universal (its fields run 1..18). RecordRef is used
        // because an unknown field number is not expressible through the typed Record API --
        // there is no member to name -- and SetLoadFields on RecordRef takes the number.
        RecRef.Open(Database::"ALT Universal");
        asserterror RecRef.SetLoadFields(9999);

        // Assert the specific diagnostic, not merely that something was raised: the error must
        // name the offending field number, so that a caller can tell WHICH number was rejected.
        // A bare non-empty check would also pass on an unrelated failure (e.g. Open() throwing).
        // (IsSubstring itself errors when the substring is absent, naming both texts.)
        Assert.IsSubstring(GetLastErrorText(), '9999');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
