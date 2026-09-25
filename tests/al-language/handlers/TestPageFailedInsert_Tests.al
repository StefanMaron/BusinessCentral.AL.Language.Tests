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
/// Each arm runs its page calls inside one asserterror, recording the name of the call it is
/// about to make. The last line of every drive procedure raises NO-ERROR-RAISED, so an arm whose
/// page calls all succeed still produces an error, and the observation says so instead of the
/// asserterror failing without detail. The observation is 'step=<the call that raised>;error=<what
/// it raised>'.
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
    procedure DelayedCard_DuplicateKey_OK_RaisesTheInsertError()
    // CLAIM: the same insert reached through the OK action raises the same error from OK().Invoke().
    begin
        Initialize();

        asserterror DriveDelayedCard(true);

        Assert.AreEqual('step=OK;error=already exists', Observe(),
            'which call raised, and what, when OK() cannot insert the new Card row');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_New_RaisesTheInsertError()
    // CLAIM: on a DelayedInsert List, New() leaves the started line and inserts it; when that
    // insert fails, New() raises the duplicate-key error.
    begin
        Initialize();

        asserterror DriveDelayedList(true);

        Assert.AreEqual('step=New;error=already exists', Observe(),
            'which call raised, and what, when New() cannot insert the line it leaves');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_Next_RaisesTheInsertError()
    // CLAIM: Next() leaving the started line inserts it the same way, and raises the same error.
    begin
        Initialize();

        asserterror DriveDelayedList(false);

        Assert.AreEqual('step=Next;error=already exists', Observe(),
            'which call raised, and what, when Next() cannot insert the line it leaves');
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

    local procedure DriveDelayedList(ViaNew: Boolean)
    var
        Rows: TestPage "IPF Delayed List";
    begin
        Step := 'OpenNew';
        Rows.OpenNew();
        Step := 'No.SetValue';
        Rows."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Rows.Description.SetValue('typed');
        if ViaNew then begin
            Step := 'New';
            Rows.New();
        end else begin
            Step := 'Next';
            Rows.Next();
        end;
        Step := 'Close';
        Rows.Close();
        Step := 'completed';
        Error(NoErrorRaisedTxt);
    end;
}
