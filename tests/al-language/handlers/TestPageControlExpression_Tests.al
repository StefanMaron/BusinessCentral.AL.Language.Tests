// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: TPCE Row (60257), TPCE Card (60258), TPCE State (60260), Assert (60021)
//
// Visible, Editable and Enabled on a page control take an AL client expression. These tests read
// each shape of that grammar in both input states, opening a fresh page for each state with the
// page globals seeded before the page exists.
//
// Two tests at the end are still MEASUREMENTS, written to fail so CI reports what BC answers:
// one for whether a control property expression can read the source record at all, one for
// whether a change made after the page is open is observable. Both compare a transcript to a
// placeholder, so Assert.AreEqual prints the actual alongside it.

codeunit 60259 "TPCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        State: Codeunit "TPCE State";

    local procedure Initialize(Hide: Boolean; Second: Boolean; Flag: Boolean; Value: Text[30])
    var
        Row: Record "TPCE Row";
    begin
        State.SetHide(Hide);
        State.SetSecond(Second);

        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Flag := Flag;
        Row.Value := Value;
        Row.Insert();
    end;

    local procedure B(Value: Boolean): Text
    begin
        if Value then
            exit('1');
        exit('0');
    end;

    // ---- a bare page global: the baseline -----------------------------------------------------

    [Test]
    procedure PlainGlobal_IsHiddenWhenTheGlobalIsFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.PlainGlobal.Visible(), 'Visible = HideIt must be false while HideIt is false');
        Card.Close();
    end;

    [Test]
    procedure PlainGlobal_IsVisibleWhenTheGlobalIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.PlainGlobal.Visible(), 'Visible = HideIt must be true while HideIt is true');
        Card.Close();
    end;

    // ---- not ----------------------------------------------------------------------------------

    [Test]
    procedure NotGlobal_IsVisibleWhenTheGlobalIsFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.NotGlobal.Visible(), 'Visible = not HideIt must be true while HideIt is false');
        Card.Close();
    end;

    [Test]
    procedure NotGlobal_IsHiddenWhenTheGlobalIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.NotGlobal.Visible(), 'Visible = not HideIt must be false while HideIt is true');
        Card.Close();
    end;

    // ---- and: three of the four input combinations are false ----------------------------------

    [Test]
    procedure AndGlobals_AreHiddenWhenOnlyOneOperandIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.AndGlobals.Visible(), 'HideIt and SecondFlag must be false while only HideIt is true');
        Card.Close();
    end;

    [Test]
    procedure AndGlobals_AreVisibleWhenBothOperandsAreTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, true, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.AndGlobals.Visible(), 'HideIt and SecondFlag must be true while both are true');
        Card.Close();
    end;

    // ---- or: read in the SAME two states as and, and disagreeing in one of them ---------------

    [Test]
    procedure OrGlobals_AreVisibleWhenOnlyOneOperandIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(true, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.OrGlobals.Visible(), 'HideIt or SecondFlag must be true while HideIt is true');
        Card.Close();
    end;

    [Test]
    procedure OrGlobals_AreHiddenWhenBothOperandsAreFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.OrGlobals.Visible(), 'HideIt or SecondFlag must be false while both are false');
        Card.Close();
    end;

    // ---- not over a parenthesized group -------------------------------------------------------

    [Test]
    procedure NotParenthesized_IsVisibleWhenBothOperandsAreFalse()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.NotParenthesized.Visible(), 'not (HideIt or SecondFlag) must be true while both are false');
        Card.Close();
    end;

    [Test]
    procedure NotParenthesized_IsHiddenWhenOneOperandIsTrue()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, true, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.NotParenthesized.Visible(), 'not (HideIt or SecondFlag) must be false once SecondFlag is true');
        Card.Close();
    end;

    // ---- the same grammar on Editable and Enabled ---------------------------------------------

    [Test]
    procedure NotGlobal_GovernsEditable()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.NotEditable.Editable(), 'Editable = not HideIt must be true while HideIt is false');
        Card.Close();

        Initialize(true, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.NotEditable.Editable(), 'Editable = not HideIt must be false while HideIt is true');
        Card.Close();
    end;

    [Test]
    procedure NotGlobal_GovernsEnabled()
    var
        Card: TestPage "TPCE Card";
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsTrue(Card.NotEnabled.Enabled(), 'Enabled = not HideIt must be true while HideIt is false');
        Card.Close();

        Initialize(true, false, false, 'Some Value');
        Card.OpenEdit();
        Assert.IsFalse(Card.NotEnabled.Enabled(), 'Enabled = not HideIt must be false while HideIt is true');
        Card.Close();
    end;

    // ---- measurements, written to fail --------------------------------------------------------

    // Can a control property expression read the source record? Opens on a row with Flag true and
    // then on a row with Flag false, reading the two Rec-field-reference controls each time. If
    // the record is readable, the transcript reads '10' then '01'. If the expression is evaluated
    // before the record is loaded, both reads answer as if Flag were false and it reads '01' twice.
    [Test]
    procedure Measure_CanAControlPropertyExpressionReadTheRecord()
    var
        Card: TestPage "TPCE Card";
        T: Text;
    begin
        Initialize(false, false, true, 'Some Value');
        Card.OpenEdit();
        T := 'flagged=' + B(Card.RecFieldRef.Visible()) + B(Card.NotRecFieldRef.Visible())
           + ' f6=' + Card.RecFieldRef.Value();
        Card.Close();

        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        T += ' unflagged=' + B(Card.RecFieldRef.Visible()) + B(Card.NotRecFieldRef.Visible());
        Card.Close();

        Assert.AreEqual('MEASURE', T, 'record-readable transcript');
    end;

    // Is a change made after the page is open observable? Reads the baseline and its negation,
    // changes the global behind them through the SingleInstance codeunit, calls CurrPage.Update
    // through a control's OnValidate, and reads again.
    [Test]
    procedure Measure_IsALaterChangeObservable()
    var
        Card: TestPage "TPCE Card";
        T: Text;
    begin
        Initialize(false, false, false, 'Some Value');
        Card.OpenEdit();
        T := 'open=' + B(Card.PlainGlobal.Visible()) + B(Card.NotGlobal.Visible());

        State.SetHide(true);
        T += ' afterStateChange=' + B(Card.PlainGlobal.Visible()) + B(Card.NotGlobal.Visible());

        Card.Close();
        Card.OpenEdit();
        T += ' afterReopen=' + B(Card.PlainGlobal.Visible()) + B(Card.NotGlobal.Visible());
        Card.Close();

        Assert.AreEqual('MEASURE', T, 'liveness transcript');
    end;
}
