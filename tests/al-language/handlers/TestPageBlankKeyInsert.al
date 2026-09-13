// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
// Scope: in-scope
// Fixtures used: TPBK Row (60572), TPBK Log (60573), TPBK Card (60574), TPBK Delayed Card (60575), TPBK List (60580)
//
/// <summary>
/// When a page-driven new record whose primary key is still BLANK is written to the table.
///
/// The No. Series pattern: <c>OpenNew()</c>, write a non-key field, read the number the table's
/// OnInsert assigned. Base Application tests rely on the number being there before the page is
/// closed (e.g. "ERM Fixed Asset Card".SetFAPostingGroupOnNewFixedAsset). The fixture table does
/// the same thing without Base Application: OnInsert fills a blank "No." with AUTO1 and logs the
/// Description it saw.
///
/// Each test builds one observation string and compares it whole, so a failure shows every
/// observed value at once.
///
/// Companion claims already in the corpus: typing only the KEY of a new Card row does not insert
/// it before Close (TRT Tests 60844, Close_WithoutOK_StillPersistsTheNewRow); on a List the row is
/// inserted once its key is typed, before the next control's write (60636,
/// NewAndInsertRecordEvents_PageDrivenInsert_FireForTheKeyOnly).
/// </summary>
codeunit 60576 "TPBK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPBK Row";
        Log: Record "TPBK Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
    end;

    local procedure Observe(): Text
    var
        Row: Record "TPBK Row";
        Log: Record "TPBK Log";
    begin
        if Log.Get('INS') then;
        exit(StrSubstNo('rows=%1;inserts=%2;descAtInsert=%3', Row.Count(), Log.InsertCount(), Log."Description At Insert"));
    end;

    [Test]
    procedure Card_BlankKey_NonKeyWrite_InsertsTheRowBeforeClose()
    // CLAIM: on a DelayedInsert=false Card, the first non-key write to a new record with a blank
    // key inserts it right away: OnInsert runs once, after the written value is on the record.
    var
        Card: TestPage "TPBK Card";
        Observed: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Description.SetValue('x');
        // No page interaction between the write and the observation.
        Observed := Observe();
        Card.Close();

        Assert.AreEqual('rows=1;inserts=1;descAtInsert=x', Observed, 'table state right after Description.SetValue on a new Card');
    end;

    [Test]
    procedure Card_BlankKey_NonKeyWrite_KeyControlShowsTheAssignedNumber()
    // CLAIM: after that write, the page's key control reads the number OnInsert assigned.
    var
        Row: Record "TPBK Row";
        Card: TestPage "TPBK Card";
        No: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Description.SetValue('x');
        No := Card."No.".Value();
        Card.Close();

        Assert.AreEqual('AUTO1', No, 'the "No." control before Close');
        Assert.IsTrue(Row.Get('AUTO1'), 'the row OnInsert numbered must exist after Close');
        Assert.AreEqual('x', Row.Description, 'the row''s Description after Close');
    end;

    [Test]
    procedure Card_BlankKey_TwoNonKeyWrites_InsertOnce()
    // CLAIM: a second write after the insert is a modify of the same row; OnInsert does not run
    // again, and Close does not insert a second row.
    var
        Row: Record "TPBK Row";
        Card: TestPage "TPBK Card";
        Observed: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Description.SetValue('x');
        Card.Description.SetValue('y');
        Card.Close();
        Observed := Observe();

        Assert.AreEqual('rows=1;inserts=1;descAtInsert=x', Observed, 'table state after two writes and Close');
        Assert.IsTrue(Row.Get('AUTO1'), 'the numbered row after Close');
        Assert.AreEqual('y', Row.Description, 'the second write must have reached the row');
    end;

    [Test]
    procedure Card_TypedKey_ThenNonKeyWrite_InsertsBeforeClose()
    // CLAIM: typing the key alone does not insert a Card row (60844), but the write to the next,
    // non-key control does.
    var
        Card: TestPage "TPBK Card";
        AfterKey: Text;
        AfterNonKey: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('K1');
        AfterKey := Observe();
        Card.Description.SetValue('x');
        AfterNonKey := Observe();
        Card.Close();

        Assert.AreEqual('after key: rows=0;inserts=0;descAtInsert= | after description: rows=1;inserts=1;descAtInsert=x',
            'after key: ' + AfterKey + ' | after description: ' + AfterNonKey, 'table state while filling a new Card whose key is typed');
    end;

    [Test]
    procedure DelayedCard_BlankKey_NonKeyWrite_InsertsOnlyOnClose()
    // CLAIM: with DelayedInsert = true, the same write does not insert the row; Close does.
    var
        Row: Record "TPBK Row";
        Card: TestPage "TPBK Delayed Card";
        Observed: Text;
        No: Text;
    begin
        Initialize();

        Card.OpenNew();
        Card.Description.SetValue('x');
        Observed := Observe();
        No := Card."No.".Value();
        Card.Close();

        Assert.AreEqual('before close: rows=0;inserts=0;descAtInsert=;no=', 'before close: ' + Observed + ';no=' + No,
            'table state and "No." control before Close on a DelayedInsert Card');
        Assert.IsTrue(Row.Get('AUTO1'), 'Close must insert the numbered row');
        Assert.AreEqual('x', Row.Description, 'the row''s Description after Close');
    end;

    [Test]
    procedure List_BlankKey_NonKeyWrite_InsertsTheRowBeforeClose()
    // CLAIM: on a DelayedInsert=false List, the first non-key write to a new line with a blank key
    // inserts it right away, as on the Card.
    var
        Rows: TestPage "TPBK List";
        Observed: Text;
        No: Text;
    begin
        Initialize();

        Rows.OpenNew();
        Rows.Description.SetValue('x');
        Observed := Observe();
        No := Rows."No.".Value();
        Rows.Close();

        Assert.AreEqual('rows=1;inserts=1;descAtInsert=x;no=AUTO1', Observed + ';no=' + No,
            'table state and "No." control right after Description.SetValue on a new List line');
    end;
}
