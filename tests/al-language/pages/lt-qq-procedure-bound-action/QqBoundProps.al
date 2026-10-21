// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QqBoundObjects.al
// Probe: AL Runner issue 3762. An action or an action group whose Visible or Enabled is a procedure call (warning AL0573): what the TestPage
// action answers for Visible() and Enabled(), what Invoke() does, and whether the procedure runs. Actions bound to a Boolean variable and an
// action with no property are the comparison.
// BC versions: 27+

codeunit 87203 "LT QQ Bound Props"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QQ Bound Log";

    local procedure Setup()
    var
        Row: Record "LT QQ Bound Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Clear();
    end;

    [Test]
    procedure QQ_ProcBound_VisibleEnabled()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        Setup();
        Card.OpenView();
        Observer.Observe('log after open', Log.Read());
        Observer.Observe('VisibleTrueProc visible', Format(Card.VisibleTrueProc.Visible()));
        Observer.Observe('VisibleTrueProc enabled', Format(Card.VisibleTrueProc.Enabled()));
        Observer.Observe('VisibleFalseProc visible', Format(Card.VisibleFalseProc.Visible()));
        Observer.Observe('VisibleFalseProc enabled', Format(Card.VisibleFalseProc.Enabled()));
        Observer.Observe('EnabledTrueProc visible', Format(Card.EnabledTrueProc.Visible()));
        Observer.Observe('EnabledTrueProc enabled', Format(Card.EnabledTrueProc.Enabled()));
        Observer.Observe('EnabledFalseProc visible', Format(Card.EnabledFalseProc.Visible()));
        Observer.Observe('EnabledFalseProc enabled', Format(Card.EnabledFalseProc.Enabled()));
        Observer.Observe('VisibleVariable visible', Format(Card.VisibleVariable.Visible()));
        Observer.Observe('EnabledVariable enabled', Format(Card.EnabledVariable.Enabled()));
        Observer.Observe('NoProperty visible', Format(Card.NoProperty.Visible()));
        Observer.Observe('NoProperty enabled', Format(Card.NoProperty.Enabled()));
        Observer.Observe('InGroupVisibleProc visible', Format(Card.InGroupVisibleProc.Visible()));
        Observer.Observe('InGroupVisibleProc enabled', Format(Card.InGroupVisibleProc.Enabled()));
        Observer.Observe('InGroupVisibleVariable visible', Format(Card.InGroupVisibleVariable.Visible()));
        Observer.Observe('log after reads', Log.Read());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure QQ_ProcBound_Invoke()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        Setup();
        Card.OpenView();
        Log.Clear();
        asserterror begin
            Card.VisibleTrueProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke VisibleTrueProc');
        Observer.Observe('log VisibleTrueProc', Log.Read());
        Log.Clear();
        asserterror begin
            Card.VisibleFalseProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke VisibleFalseProc');
        Observer.Observe('log VisibleFalseProc', Log.Read());
        Log.Clear();
        asserterror begin
            Card.EnabledTrueProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke EnabledTrueProc');
        Observer.Observe('log EnabledTrueProc', Log.Read());
        Log.Clear();
        asserterror begin
            Card.EnabledFalseProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke EnabledFalseProc');
        Observer.Observe('log EnabledFalseProc', Log.Read());
        Log.Clear();
        asserterror begin
            Card.InGroupVisibleProc.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke InGroupVisibleProc');
        Observer.Observe('log InGroupVisibleProc', Log.Read());
        Log.Clear();
        asserterror begin
            Card.NoProperty.Invoke();
            Error('');
        end;
        Observer.ObserveError('invoke NoProperty');
        Observer.Observe('log NoProperty', Log.Read());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure QQ_ProcBound_EditMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QQ Bound Card";
    begin
        // The same reads on a page opened for edit, after a move to the row.
        Setup();
        Card.OpenEdit();
        Card.GoToKey(1);
        Observer.Observe('VisibleTrueProc visible', Format(Card.VisibleTrueProc.Visible()));
        Observer.Observe('VisibleFalseProc visible', Format(Card.VisibleFalseProc.Visible()));
        Observer.Observe('EnabledTrueProc enabled', Format(Card.EnabledTrueProc.Enabled()));
        Observer.Observe('EnabledFalseProc enabled', Format(Card.EnabledFalseProc.Enabled()));
        Observer.Observe('InGroupVisibleProc visible', Format(Card.InGroupVisibleProc.Visible()));
        Observer.Observe('log', Log.Read());
        Card.Close();
        Observer.Finish();
    end;
}
