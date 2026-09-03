// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TPCE Row (60257), TPCE Card (60258), Assert (60021)
//
// MEASUREMENT PASS — these three tests are written to FAIL, on purpose, so that CI reports what
// real BC answers. Each builds a transcript of every control property it reads and compares it to
// a placeholder, so Assert.AreEqual prints both the placeholder and the actual transcript. The
// transcript is the measurement; the assertions that ship will be written from it.
//
// The question being measured: Visible, Editable and Enabled on a page control take an AL client
// expression, and the first attempt at this suite assumed a TestPage observes such an expression
// re-evaluated live after its inputs change. Real BC disagreed on 8 of 8 versions, including on
// the baseline shape `Visible = HideIt`, so what a TestPage actually observes has to be measured
// before anything asserts it.
//
// Transcript alphabet: '1' true, '0' false, 'E' the read raised an error.

codeunit 60259 "TPCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Reset()
    var
        Row: Record "TPCE Row";
    begin
        Row.DeleteAll();
    end;

    local procedure AddRow(PK: Code[10]; Value: Text[30]; Flag: Boolean)
    var
        Row: Record "TPCE Row";
    begin
        Row.Init();
        Row.PK := PK;
        Row.Value := Value;
        Row.Flag := Flag;
        Row.Insert();
    end;

    local procedure B(Value: Boolean): Text
    begin
        if Value then
            exit('1');
        exit('0');
    end;

    // Every control read in one pass, in a fixed order, so one transcript covers the whole shape
    // matrix. Order: PlainGlobal, NotGlobal, AndGlobals, OrGlobals, NotParenthesized, RecFieldRef,
    // NotRecFieldRef, Comparison, OpenTimeGlobal, NotOpenTimeGlobal, then NotEditable.Editable and
    // NotEnabled.Enabled.
    local procedure ReadAll(var Card: TestPage "TPCE Card"): Text
    begin
        exit(
            B(Card.PlainGlobal.Visible()) +
            B(Card.NotGlobal.Visible()) +
            B(Card.AndGlobals.Visible()) +
            B(Card.OrGlobals.Visible()) +
            B(Card.NotParenthesized.Visible()) +
            B(Card.RecFieldRef.Visible()) +
            B(Card.NotRecFieldRef.Visible()) +
            B(Card.Comparison.Visible()) +
            B(Card.OpenTimeGlobal.Visible()) +
            B(Card.NotOpenTimeGlobal.Visible()) +
            B(Card.NotEditable.Editable()) +
            B(Card.NotEnabled.Enabled()));
    end;

    // Measurement 1: does anything a TestPage sets after the page is open change what these
    // properties report? Reads the whole matrix at open, then after each of the three toggles,
    // and also reads each toggle back so a toggle that did not take is distinguishable from a
    // property that did not re-evaluate.
    [Test]
    procedure Measure_LiveUpdates()
    var
        Card: TestPage "TPCE Card";
        T: Text;
    begin
        Reset();
        AddRow('ROW1', 'Some Value', false);

        Card.OpenEdit();
        T := 'open=' + ReadAll(Card);

        Card.ToggleHide.SetValue(true);
        T += ' hide=' + ReadAll(Card) + ' hideRead=' + B(Card.ToggleHide.AsBoolean());

        Card.ToggleLock.SetValue(true);
        T += ' lock=' + ReadAll(Card) + ' lockRead=' + B(Card.ToggleLock.AsBoolean());

        Card.ToggleFlag.SetValue(true);
        T += ' flag=' + ReadAll(Card) + ' flagRead=' + B(Card.ToggleFlag.AsBoolean());

        Card.Close();

        Assert.AreEqual('MEASURE', T, 'live-update transcript');
    end;

    // Measurement 2: what do the record-driven shapes report at open time, on a row whose Flag is
    // TRUE and whose Value is blank — the mirror of measurement 1's row. If a control property
    // expression can read the record at all, RecFieldRef and OpenTimeGlobal answer differently
    // here than they do above, and Comparison answers '0'.
    [Test]
    procedure Measure_OpenedOnAFlaggedRow()
    var
        Card: TestPage "TPCE Card";
        T: Text;
    begin
        Reset();
        AddRow('ROW1', '', true);

        Card.OpenEdit();
        T := 'open=' + ReadAll(Card) + ' pk=' + Card.PlainGlobal.Value();
        Card.Close();

        Assert.AreEqual('MEASURE', T, 'flagged-row transcript');
    end;

    // Measurement 3: the mirror of 2 on a row whose Flag is FALSE and whose Value is not blank,
    // read WITHOUT touching anything. Between 2 and 3, any property that differs is one the
    // record can drive at open time; any property that does not differ is one it cannot.
    [Test]
    procedure Measure_OpenedOnAnUnflaggedRow()
    var
        Card: TestPage "TPCE Card";
        T: Text;
    begin
        Reset();
        AddRow('ROW1', 'Some Value', false);

        Card.OpenEdit();
        T := 'open=' + ReadAll(Card) + ' pk=' + Card.PlainGlobal.Value();
        Card.Close();

        Assert.AreEqual('MEASURE', T, 'unflagged-row transcript');
    end;
}
