// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-confirm-method
// Scope: in-scope
//
// CLAIM: Confirm(Question, Default, Args) substitutes %1/%2/... placeholders in
// Question with Args (same substitution semantics as StrSubstNo) before the
// question reaches a declared [ConfirmHandler]. Covers more than one argument,
// a non-text argument type (integer, decimal, date), and that Default is honored
// when the handler does not override the reply.

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
    procedure Confirm_SingleFormatArg_HandlerReceivesSubstitutedQuestion()
    begin
        Initialize();

        if Confirm('%1 configurations are created. Do you want to view them?', true, 2) then;

        Assert.AreEqual(1, ConfirmFireCount, 'ConfirmHandler must fire exactly once');
        Assert.ExpectedConfirm('2 configurations are created. Do you want to view them?', LastConfirmQuestion);
    end;

    [Test]
    [HandlerFunctions('AnswerNo')]
    procedure Confirm_MultipleMixedTypeFormatArgs_HandlerReceivesSubstitutedQuestion()
    var
        SomeDate: Date;
    begin
        Initialize();
        SomeDate := DMY2Date(15, 1, 2024);

        if Confirm('Delete %1 records for %2 dated %3?', true, 3, 'Customer', SomeDate) then;

        Assert.AreEqual(1, ConfirmFireCount, 'ConfirmHandler must fire exactly once');
        Assert.ExpectedConfirm(
            StrSubstNo('Delete %1 records for %2 dated %3?', 3, 'Customer', SomeDate),
            LastConfirmQuestion);
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
