// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001), ABPageEventFixtures.al
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: what the page trigger events do around the page's own triggers: order against the trigger, the arguments (Rec, xRec, BelowxRec),
// the allow flag a subscriber can clear (insert, modify, close), the order of several subscribers, and that a TestPage raises them.

codeunit 77053 "LT AB Page Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AB Row";
        Flags: Codeunit "LT AB Flags";
        Log: Codeunit "LT AB Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Flags.SetVeto(false);
        Log.Reset();
    end;

    [Test]
    procedure OpenAndCloseOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Rows.OpenView();
        Observer.Observe('after-open', Log.Dump());
        Log.Reset();
        Rows.Close();
        Observer.Observe('after-close', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure NavigationRaisesAfterGetCurrRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Rows.OpenView();
        Log.Reset();
        Rows.Next();
        Observer.Observe('after-next', Log.Dump());
        Log.Reset();
        Rows.Previous();
        Observer.Observe('after-previous', Log.Dump());
        Rows.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NewRowThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Rows.OpenEdit();
        Log.Reset();
        Rows.New();
        Observer.Observe('after-new', Log.Dump());
        Log.Reset();
        Rows.IdF.SetValue(10);
        Observer.Observe('after-id', Log.Dump());
        Log.Reset();
        Rows.NameF.SetValue('Ten');
        Observer.Observe('after-name', Log.Dump());
        Log.Reset();
        Rows.Next();
        Observer.Observe('after-leave-row', Log.Dump());
        Rows.Close();
        Observer.Observe('stored-count', Format(Stored.Count()));
        Observer.Observe('stored-ten-exists', Format(Stored.Get(10)));
        Observer.Finish();
    end;

    [Test]
    procedure ModifyRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Rows.OpenEdit();
        Log.Reset();
        Rows.NameF.SetValue('Changed');
        Observer.Observe('after-setvalue', Log.Dump());
        Log.Reset();
        Rows.Next();
        Observer.Observe('after-leave-row', Log.Dump());
        Rows.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure ModifyVetoedBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Flags.SetVeto(true);
        Rows.OpenEdit();
        Log.Reset();
        Rows.NameF.SetValue('Vetoed');
        asserterror Rows.Next();
        Observer.ObserveError('next-after-veto');
        Observer.Observe('log', Log.Dump());
        Rows.Close();
        Stored.Get(1);
        Observer.Observe('stored-name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure InsertVetoedBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Stored: Record "LT AB Row";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Flags.SetVeto(true);
        Rows.OpenEdit();
        Rows.New();
        Rows.IdF.SetValue(20);
        Log.Reset();
        Rows.NameF.SetValue('Twenty');
        asserterror Rows.Next();
        Observer.ObserveError('next-after-veto');
        Observer.Observe('log', Log.Dump());
        Rows.Close();
        Observer.Observe('stored-count', Format(Stored.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure CloseVetoedBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
        Rows: TestPage "LT AB Event Rows";
    begin
        Seed();
        Flags.SetVeto(true);
        Rows.OpenView();
        Log.Reset();
        asserterror Rows.Close();
        Observer.ObserveError('close-after-veto');
        Observer.Observe('log', Log.Dump());
        Flags.SetVeto(false);
        Observer.Finish();
    end;
}
