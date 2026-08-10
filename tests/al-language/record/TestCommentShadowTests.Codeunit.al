// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-simple-statements#comments
// Scope: in-scope
// Fixtures used: CSFP Flag Table (60900)
//
// Migrated from AL Runner tests/runner-extras/comment-shadowed-properties (CsfpTests.Codeunit.al).
// These assert compiler-level AL semantics that any conforming implementation must honour: a
// commented-out property does not shadow the declared one, and a '//' inside a string literal
// does not start a comment. Trivially true on a real tier -- which is exactly why the tier,
// not the runner, should be the one to say so.

// Issue #1690: a comment mentioning 'InitValue =' was parsed as the field's InitValue,
// so Insert threw NavNCLEvaluateException with the comment prose as the value. These
// pin the concrete parsed values, not just "it did not crash".
codeunit 60901 "CSFP Comment Shadow Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure InsertAppliesTheDeclaredInitValueNotTheCommentText()
    var
        Flag: Record "CSFP Flag Table";
    begin
        // [WHEN] A row is inserted without touching Accept.
        Flag.Init();
        Flag."Code" := 'A';
        Flag.Insert(false);

        // [THEN] It carries the DECLARED InitValue. Before the fix this line was never
        // reached: Insert threw NavNCLEvaluateException because the field's InitValue was
        // the comment prose ('true: new rows default to accepted. ...').
        Flag.Get('A');
        Assert.IsTrue(Flag.Accept, 'Accept must default to true via the declared InitValue');
    end;

    [Test]
    procedure CommentMentioningCaptionDoesNotOverrideTheDeclaredCaption()
    var
        Flag: Record "CSFP Flag Table";
    begin
        // [THEN] The block comment naming a different Caption is prose, not a property.
        Assert.AreEqual('Ratio // Net', Flag.FieldCaption(Ratio),
            'the declared Caption must win over the one named in the comment');
    end;

    [Test]
    procedure SlashesInsideAStringLiteralAreNotTreatedAsAComment()
    var
        Flag: Record "CSFP Flag Table";
    begin
        // [THEN] Negative direction: the comment pass must not over-reach. Truncating at
        // the '//' would leave 'Ratio ' here.
        Assert.AreEqual('Ratio // Net', Flag.FieldCaption(Ratio),
            'a // inside a string literal is literal text, not a comment');
        Assert.AreEqual('Accept', Flag.FieldCaption(Accept),
            'an ordinary caption on a commented field is still parsed');
    end;
}
