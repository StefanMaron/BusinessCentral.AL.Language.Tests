// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
// Scope: in-scope
// Fixtures used: IPF Row (60039), IPF Card (60027), IPF Delayed Card (60025), IPF Delayed List (60026), Assert (60021)
//
/// <summary>
/// What a test sees when the page's own insert of a new row FAILS, at each moment a TestPage
/// writes a started row: insert on focus, Close(), OK(), New() and Next().
///
/// The failure is the platform's duplicate-key refusal: a row "DUP" exists, and the test types
/// "DUP" into a new record. The fixture table has no triggers, so nothing but the insert itself
/// can fail.
///
/// The raising arms run their page calls inside one asserterror, recording the name of the call
/// they are about to make; the observation is 'step=<the call that raised>;error=<what it raised>'.
/// The List arms raise nothing on any leg, so they record what happened to the line instead: the
/// cursor's key after New()/Next(), both fields' validation error counts, and the table afterwards.
///
/// Measured on real BC (corpus run 36145940845, all nine cloud legs): insert on focus and Close()
/// raise at the call; OK().Invoke() raises nothing itself and the error surfaces when the TestPage
/// variable goes out of scope; New() and Next() on a DelayedInsert List raise nothing at all.
///
/// Written for AL Runner#4624, where the runner's page-driven insert trapped the error and the
/// row, with every value typed into it, disappeared without one.
/// </summary>
codeunit 60045 "IPF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Step: Text;
        NoErrorRaisedTxt: Label 'NO-ERROR-RAISED', Locked = true;

    local procedure Initialize()
    var
        Row: Record "IPF Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'DUP';
        Row.Description := 'orig';
        Row.Insert();
        Step := '';
    end;

    local procedure Observe(): Text
    var
        ErrorText: Text;
    begin
        ErrorText := GetLastErrorText();
        if StrPos(ErrorText, 'already exists') > 0 then
            ErrorText := 'already exists';
        exit(StrSubstNo('step=%1;error=%2', Step, ErrorText));
    end;

    [Test]
    procedure Card_DuplicateKey_InsertOnFocus_RaisesAtTheNonKeyWrite()
    // CLAIM: on a DelayedInsert=false Card, the write to the first non-key control inserts the new
    // row (TPBK Tests 60576). When that insert fails, the SetValue that triggered it raises the
    // duplicate-key error.
    begin
        Initialize();

        asserterror DriveCardInsertOnFocus();

        Assert.AreEqual('step=Description.SetValue;error=already exists', Observe(),
            'which call raised, and what, when the insert-on-focus of a new Card row fails');
    end;

    [Test]
    procedure DelayedCard_DuplicateKey_Close_RaisesTheInsertError()
    // CLAIM: on a DelayedInsert Card, Close() inserts the new row; when that insert fails,
    // Close() raises the duplicate-key error.
    begin
        Initialize();

        asserterror DriveDelayedCard(false);

        Assert.AreEqual('step=Close;error=already exists', Observe(),
            'which call raised, and what, when Close() cannot insert the new Card row');
    end;

    [Test]
    procedure DelayedCard_DuplicateKey_OK_RaisesWhenThePageGoesOutOfScope()
    // MEASURED (corpus run 36145940845, all nine cloud legs): OK().Invoke() itself raises nothing
    // when the insert fails. The duplicate-key error surfaces later, once the drive procedure
    // returns and its TestPage variable is released. Here the drive procedure ends normally after
    // OK(), so the only error the asserterror can catch is that one.
    begin
        Initialize();

        asserterror DriveDelayedCardViaOK();

        Assert.AreEqual('step=completed;error=already exists', Observe(),
            'which call raised, and what, when OK() cannot insert the new Card row');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_New_RaisesNothing()
    // MEASURED (corpus run 36145940845, all nine cloud legs): on a DelayedInsert List, New() after
    // a started line whose insert would fail raises no error, and neither does the Close() after
    // it. This arm records what happens to that line: the field validation errors, where the
    // cursor is, and what the table holds once the page is closed.
    begin
        Initialize();

        Assert.AreEqual('cur=;noErr=0;descErr=0;rows=1;dup=orig', DriveDelayedListObserved('DUP', true),
            'what New() does with a started line whose insert fails');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_Next_RaisesNothing()
    // MEASURED (corpus run 36145940845, all nine cloud legs): the same through Next().
    begin
        Initialize();

        Assert.AreEqual('cur=;noErr=0;descErr=0;rows=1;dup=orig', DriveDelayedListObserved('DUP', false),
            'what Next() does with a started line whose insert fails');
    end;

    [Test]
    procedure DelayedList_NewKey_New_InsertsTheLine()
    // CLAIM (contrast): with a key that does not exist yet, New() inserts the started line with its
    // typed value, so the duplicate-key arms above differ only in the insert failing.
    var
        Row: Record "IPF Row";
    begin
        Initialize();

        Assert.AreEqual('cur=;noErr=0;descErr=0;rows=2;dup=orig', DriveDelayedListObserved('NEW1', true),
            'what New() does with a started line whose insert succeeds');
        Assert.IsTrue(Row.Get('NEW1'), 'New() must insert the started line');
        Assert.AreEqual('typed', Row.Description, 'the inserted line''s Description');
    end;

    [Test]
    procedure DelayedCard_NewKey_Close_InsertsTheRow()
    // CLAIM (contrast): the same page calls with a key that does not exist yet raise nothing, and
    // Close() writes the row with its typed value while the existing row keeps its own.
    var
        Row: Record "IPF Row";
        Card: TestPage "IPF Delayed Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('NEW1');
        Card.Description.SetValue('typed');
        Card.Close();

        Assert.IsTrue(Row.Get('NEW1'), 'Close() must insert the new row');
        Assert.AreEqual('typed', Row.Description, 'the new row''s Description after Close()');
        Row.Get('DUP');
        Assert.AreEqual('orig', Row.Description, 'the existing row''s Description after Close()');
    end;

    local procedure DriveCardInsertOnFocus()
    var
        Card: TestPage "IPF Card";
    begin
        Step := 'OpenNew';
        Card.OpenNew();
        Step := 'No.SetValue';
        Card."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Card.Description.SetValue('typed');
        Step := 'Close';
        Card.Close();
        Step := 'completed';
        Error(NoErrorRaisedTxt);
    end;

    local procedure DriveDelayedCard(ViaOK: Boolean)
    var
        Card: TestPage "IPF Delayed Card";
    begin
        Step := 'OpenNew';
        Card.OpenNew();
        Step := 'No.SetValue';
        Card."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Card.Description.SetValue('typed');
        if ViaOK then begin
            Step := 'OK';
            Card.OK().Invoke();
        end else begin
            Step := 'Close';
            Card.Close();
        end;
        Step := 'completed';
        Error(NoErrorRaisedTxt);
    end;

    local procedure DriveDelayedCardViaOK()
    var
        Card: TestPage "IPF Delayed Card";
    begin
        Step := 'OpenNew';
        Card.OpenNew();
        Step := 'No.SetValue';
        Card."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Card.Description.SetValue('typed');
        Step := 'OK';
        Card.OK().Invoke();
        Step := 'completed';
    end;

    local procedure DriveDelayedListObserved(NewKey: Code[20]; ViaNew: Boolean): Text
    var
        Row: Record "IPF Row";
        Rows: TestPage "IPF Delayed List";
        Observed: Text;
    begin
        Rows.OpenNew();
        Rows."No.".SetValue(NewKey);
        Rows.Description.SetValue('typed');
        if ViaNew then
            Rows.New()
        else
            Rows.Next();
        Observed := StrSubstNo('cur=%1;noErr=%2;descErr=%3', Rows."No.".Value(),
            Rows."No.".ValidationErrorCount(), Rows.Description.ValidationErrorCount());
        Rows.Close();
        Row.Get('DUP');
        exit(StrSubstNo('%1;rows=%2;dup=%3', Observed, Row.Count(), Row.Description));
    end;
}
