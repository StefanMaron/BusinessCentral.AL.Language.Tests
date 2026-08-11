// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-confirm-method
// Scope: in-scope
//
// CLAIM: Confirm(Question, Default, Args) does NOT substitute %1/%2/... placeholders
// in Question before the question reaches a declared [ConfirmHandler] — the handler
// receives the raw, literal format string, Args untouched. This was verified against
// real BC (27.5 and 28.3 CI): a first version of this test asserted the substituted
// text (matching the documented interactive-dialog behavior and StrSubstNo semantics)
// and failed on both versions with the raw '%1 ...' string as Actual, so the assertions
// here were corrected to match observed BC behavior rather than the doc-implied one.
//
// This is an asymmetry with Message(Question, Args), which DOES substitute before its
// [MessageHandler] runs (see Message_FormattedString_HandlerGetsFormatted in
// TestMessageHandler.al) — substitution only happens on Confirm's interactive
// (non-test) dialog path, not on the [ConfirmHandler] test-dispatch path.
//
// Covers more than one argument, a non-text argument type (integer, decimal via date),
// and that Default is honored when the handler does not override the reply.

codeunit 60952 "Test Confirm Format Args"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        ConfirmFireCount: Integer;
        LastConfirmQuestion: Text;

    [Test]
    [HandlerFunctions('AnswerNo')]
    procedure Confirm_SingleFormatArg_HandlerReceivesRawUnsubstitutedQuestion()
    begin
        Initialize();

        if Confirm('%1 configurations are created. Do you want to view them?', true, 2) then;

        Assert.AreEqual(1, ConfirmFireCount, 'ConfirmHandler must fire exactly once');
        Assert.ExpectedConfirm('%1 configurations are created. Do you want to view them?', LastConfirmQuestion);
    end;

    [Test]
    [HandlerFunctions('AnswerNo')]
    procedure Confirm_MultipleMixedTypeFormatArgs_HandlerReceivesRawUnsubstitutedQuestion()
    var
        SomeDate: Date;
    begin
        Initialize();
        SomeDate := DMY2Date(15, 1, 2024);

        if Confirm('Delete %1 records for %2 dated %3?', true, 3, 'Customer', SomeDate) then;

        Assert.AreEqual(1, ConfirmFireCount, 'ConfirmHandler must fire exactly once');
        // The placeholders stay literal — this is NOT StrSubstNo('Delete %1 records for %2 dated %3?', 3, 'Customer', SomeDate).
        Assert.ExpectedConfirm('Delete %1 records for %2 dated %3?', LastConfirmQuestion);
    end;

    [Test]
    [HandlerFunctions('AnswerReplyUnchanged')]
    procedure Confirm_DefaultChoiceHonored_WhenHandlerDoesNotOverrideReply()
    var
        ResultTrue: Boolean;
        ResultFalse: Boolean;
    begin
        Initialize();

        ResultTrue := Confirm('%1 records will be deleted. Continue?', true, 5);
        Assert.IsTrue(ResultTrue, 'Confirm must return the Default (true) when the handler leaves Reply unchanged');

        ResultFalse := Confirm('%1 records will be deleted. Continue?', false, 5);
        Assert.IsFalse(ResultFalse, 'Confirm must return the Default (false) when the handler leaves Reply unchanged');
    end;

    [ConfirmHandler]
    procedure AnswerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmFireCount += 1;
        LastConfirmQuestion := Question;
        Reply := false;
    end;

    [ConfirmHandler]
    procedure AnswerReplyUnchanged(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmFireCount += 1;
        LastConfirmQuestion := Question;
        // deliberately does not touch Reply — proves Default flows through untouched
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ConfirmFireCount := 0;
        LastConfirmQuestion := '';
    end;
}
