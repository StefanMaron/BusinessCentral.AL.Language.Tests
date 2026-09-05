// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: NRB Header (60649), NRB Line (60650), NRB Lines (60651), NRB Card (60652);
//                shared Assert (60021)
//
/// <summary>
/// Two claims about what TestPage.New() does to the record buffer, on a subpage part linked
/// by field(...).
///
/// RecordImplementation.NavForm.NewRecordAsync (Ncl 28.1) does two things in order:
///
///   1. SourceTable.InitializeFieldsFromFilters(...) -- which chains to
///      RecordImplementation.InitRecordFromFilters, whose FIRST line is
///      ResetRecordBuffer() (mutableRecordBuffer = DefaultMutableRecordBuffer) -- and only
///      then copies the part's SubPageLink values onto the fresh buffer for the fields the
///      primary-key gate allows (see StefanMaron/BusinessCentral.AL.Language.Tests#148,
///      which measured that half).
///   2. if (ValidateFieldsInOnNewRecord) SourceTable.ValidateFieldsAsync(fieldsInitializedFromFilters, ...)
///      -- runs OnValidate on exactly the fields step 1 copied, but only when this flag is set.
///
/// The first test below pins step 1's blanking, by name ResetRecordBuffer rather than the
/// ALInit some runner-side comments call it -- both amount to "start from a fresh default
/// buffer", but reading NewRecordAsync's own body for an ALInit call and finding none, as one
/// gap report did, misses that this is where the reset actually happens, one call down.
///
/// ValidateFieldsInOnNewRecord itself is a plain auto-property with no setter anywhere in
/// Ncl -- something upstream (the client, or the TestPage machinery standing in for it) has
/// to set it before calling in, and nothing here says which way. "No. Validated" answers
/// that directly: it is set by nothing except "No."'s own OnValidate trigger, and "No." is
/// the field the SubPageLink stamps, so if it reads true after New(), OnValidate ran on the
/// stamped value; if it stays at its Init() default, ValidateFieldsAsync was never called.
///
/// The claims, each in its own test:
///   - New() while positioned on an existing row does not carry that row's Descr onto the
///     new one -- ResetRecordBuffer's effect, pinned directly;
///   - New() through the field(...) link still stamps "No." (pinned already by #148, kept
///     here as the setup precondition the second assertion in the same test depends on);
///   - New() through that same link either DOES or DOES NOT run "No."'s OnValidate trigger
///     on the stamped value -- this file's best-guess assertion is that it DOES, and if a
///     real service tier disagrees the assertion flips, not the fixture.
/// </summary>
codeunit 60653 "NRB Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure AddLine(HeaderNo: Code[20]; LineNo: Integer; Descr: Text[50])
    var
        Line: Record "NRB Line";
    begin
        Line.Init();
        Line."No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure Initialize()
    var
        Header: Record "NRB Header";
        Line: Record "NRB Line";
    begin
        Header.DeleteAll();
        Line.DeleteAll();

        Header.Init();
        Header."No." := 'H1';
        Header.Insert();
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "NRB Card")
    var
        Header: Record "NRB Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    [Test]
    procedure New_WhilePositionedOnAnExistingRow_LeavesTheNewRowsDescrBlank()
    // CLAIM: New() blanks the record buffer before anything else runs. The row started while
    // the cursor sits on an existing row must not carry that row's Descr -- an implementation
    // that skips blanking (or blanks only when it happens to have no other source to copy
    // from) leaves the previous row's own value in place and fails here.
    var
        Card: TestPage "NRB Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'existing value');
        OpenCardOn('H1', Card);
        Card.Lines.First();
        Assert.AreEqual('existing value', Card.Lines.Descr.Value,
            'setup: the part must be positioned on the existing row before New() is called');

        Card.Lines.New();

        Assert.AreEqual('', Card.Lines.Descr.Value,
            'New() must blank the record buffer -- a row started while positioned on an existing row must not carry that row''s Descr');
        Card.Close();
    end;

    [Test]
    procedure New_StampsTheLinkedFieldAndValidatesIt()
    // CLAIM (first assertion, re-measuring #148's own rule as this test's precondition):
    // "No." is part of "NRB Line"'s primary key, so New() through the field(...) link stamps
    // it -- if this assertion itself fails, the second one below is not meaningful, because
    // there would be nothing for OnValidate to have run on.
    //
    // CLAIM (second assertion, the one this file exists to settle): New() also runs "No."'s
    // OnValidate trigger on the value it just stamped, not just an assignment. "No. Validated"
    // is set by nothing else, so a runtime that copies SubPageLink values as raw assignments
    // (ValidateFieldsInOnNewRecord left false) leaves it at its Init() default, while a
    // runtime that validates leaves it true.
    var
        Card: TestPage "NRB Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.Lines.New();

        Assert.AreEqual('H1', Card.Lines."No.".Value,
            '"No." is part of "NRB Line"''s primary key, so New() must stamp the link''s value onto the new row (see #148)');
        Assert.AreEqual('True', Card.Lines."No. Validated".Value,
            'New() must run "No."''s OnValidate trigger on the value it stamped from the SubPageLink, not just assign it');
        Card.Close();
    end;
}
