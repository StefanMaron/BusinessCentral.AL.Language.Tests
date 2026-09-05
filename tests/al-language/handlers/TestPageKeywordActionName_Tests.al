// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: Keyword Action Row (60267), Keyword Action List (60268), Assert (60021)
//
// Pins TestPage.<Action>.Invoke() for actions whose NAME is a C# reserved keyword
// (action(New), action(Delegate), action(Override)) or a name a .NET compiler treats as
// reserved (Finalize), alongside names that only look like keywords (Delete, Setup). In AL
// every one of these is an ordinary identifier; dispatch must not depend on the word.
//
// The in-file non-keyword arms (Delete, Setup) make the suite differential: if only the
// keyword arms fail, the word itself is the trigger. Each positive asserts a row only the
// named trigger writes; the negative asserts the trigger's OWN error text so a dispatcher
// that reached a different action, or none, cannot pass it.

codeunit 60269 "Keyword Action Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Keyword Action Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow()
    var
        Row: Record "Keyword Action Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();
    end;

    // Control: a name that is not a C# keyword dispatches. If this fails the page itself
    // is broken; if only the keyword arms fail, the word is the trigger.
    [Test]
    procedure NonKeywordActionDeleteInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Delete.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('DELETE'), 'action Delete''s OnAction must have run');
        Assert.AreEqual('A', Row.Descr, 'the trigger must run against the page''s current row');
    end;

    [Test]
    procedure NonKeywordActionSetupInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Setup.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('SETUP'), 'action Setup''s OnAction must have run');
    end;

    // Positive: an action named New - a C# reserved keyword, and also the name of the
    // TestPage.New() method - dispatches to the page's own action.
    [Test]
    procedure KeywordActionNewInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.New.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('NEW'), 'action New''s OnAction must have run');
        Assert.AreEqual('A', Row.Descr, 'the trigger must run against the page''s current row');
    end;

    [Test]
    procedure KeywordActionDelegateInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Delegate.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('DELEGATE'), 'action Delegate''s OnAction must have run');
    end;

    [Test]
    procedure ReservedMemberNameActionFinalizeInvokeRunsItsTrigger()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.Finalize.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('FINALIZE'), 'action Finalize''s OnAction must have run');
    end;

    // Positive: the promoted actionref to a keyword-named target dispatches the target.
    [Test]
    procedure PromotedActionRefToKeywordActionInvokeRunsTheTarget()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        KeywordList.New_Promoted.Invoke();
        KeywordList.Close();

        Assert.IsTrue(Row.Get('NEW'), 'actionref New_Promoted must run action New''s OnAction');
    end;

    // Negative: a keyword-named action whose trigger errors surfaces that trigger's own
    // error - proof the right trigger ran, not a different one and not none.
    [Test]
    procedure KeywordActionOverrideInvokeSurfacesItsOwnError()
    var
        Row: Record "Keyword Action Row";
        KeywordList: TestPage "Keyword Action List";
    begin
        Initialize();
        SeedRow();

        KeywordList.OpenEdit();
        KeywordList.First();
        asserterror KeywordList.Override.Invoke();
        Assert.ExpectedError('Keyword Action List action refused deliberately');

        Assert.IsFalse(Row.Get('NEW'), 'no other action''s trigger may have run');
    end;
}
