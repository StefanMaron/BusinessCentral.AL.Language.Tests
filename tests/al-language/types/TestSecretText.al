// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/secrettext/secrettext-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none; shared Assert (60021)
// BC versions: 27.0+ (SecretText is runtime 12.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: SecretText is a distinct AL data type whose runtime behavior is that a secret can be
/// built and composed, and its emptiness observed, but its value never read back in a
/// Cloud-target app. Nothing in this repository measured any part of SecretText before this
/// file -- docs/al-language-coverage-gaps.md lists it as gap #3, "not yet covered".
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. CONSTRUCTION. SecretStrSubstNo() is the way a SecretText is built in a Cloud app --
///      from a template alone, or by substituting other secrets into one. If construction ever
///      silently produced an empty secret, every IsEmpty()-is-false test below fails.
///   2. EMPTINESS. IsEmpty() is the ONLY thing a Cloud app may ask about a secret's content.
///      It is asserted in both directions, and after reassignment in both directions, so an
///      implementation returning a constant fails whichever constant it picks.
///   3. COMPOSITION CARRIES CONTENT. Substituting a populated secret into a template yields a
///      populated secret; substituting an empty one into a bare '%1' yields an empty secret.
///      That pair is what says the arguments are really interpolated rather than the result
///      being some fixed value.
///   4. SECRECY SURVIVES COPYING AND CONTAINERS. A secret assigned to another SecretText, or
///      stored in a List/Dictionary, still carries its content and is still only observable
///      through IsEmpty() -- it does not decay into readable text by being moved.
///
/// THE COMPILE-TIME HALF OF THIS CONTRACT IS NOT TESTABLE AS A [Test], and that is the more
/// important half. Measured with the AL compiler (v17.0.34.45391) against this app's Cloud
/// target -- each of these is a compile ERROR, so no runtime assertion can exist for them and
/// a test file asserting them could never be built:
///
///     T := Format(Secret);         error AL0133: cannot convert from 'SecretText' to 'Joker'
///     Message(Format(Secret));     error AL0133: (same -- no leak via the dialog path)
///     T := Secret.Unwrap();        error AL0296: 'Unwrap' has scope 'OnPrem' and cannot be
///                                  used for 'Cloud' development
///     V := Secret;                 error AL0122: cannot convert 'SecretText' to 'Variant'
///     Assert.AreEqual(S1, S2, '')  error AL0133: cannot convert 'SecretText' to 'Variant'
///     if S1 = S2 then              error AL0175: operator '=' cannot be applied to operands
///                                  of type 'SecretText' and 'SecretText'
///
/// So in a Cloud app the value cannot reach Format, a Message, a Variant, or an equality
/// comparison, and Unwrap -- the one API that returns the plain text -- is refused outright by
/// scope. This is recorded here as documentation rather than as tests because the AL compiler
/// enforces it; the same reasoning and the same AL0296 appear in
/// network/TestHttpClientBlockNoHandler.al, which records that [HttpClientHandler] is
/// OnPrem-scoped and therefore untestable from this app.
///
/// One consequence worth stating because it is counter-intuitive: there is deliberately NO
/// negative [Test] in this file. Every negative case for SecretText is a compile-time refusal,
/// not a runtime error, so `asserterror` would have nothing to catch. The runtime surface that
/// remains is total -- every operation the compiler permits is expected to succeed.
/// </summary>
codeunit 60275 "Test SecretText"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // -- Construction via SecretStrSubstNo -----------------------------------

    [Test]
    procedure SecretText_SecretStrSubstNo_TemplateOnly_IsNotEmpty()
    // CLAIM: a template with no substitutions still yields a secret carrying that template as
    // content. This is the simplest construction path and the one the other tests build on.
    var
        Secret: SecretText;
    begin
        Initialize();

        Secret := SecretStrSubstNo('a-constant-template');

        Assert.IsFalse(Secret.IsEmpty(), 'SecretStrSubstNo with only a template must carry the template as content');
    end;

    [Test]
    procedure SecretText_SecretStrSubstNo_EmptyTemplate_IsEmpty()
    // CLAIM: an empty template yields an EMPTY secret. The negative direction of the test
    // above -- an implementation that always returned a populated secret fails here, and one
    // that always returned an empty secret fails above.
    var
        Secret: SecretText;
    begin
        Initialize();

        Secret := SecretStrSubstNo('');

        Assert.IsTrue(Secret.IsEmpty(), 'SecretStrSubstNo with an empty template must yield an empty secret');
    end;

    [Test]
    procedure SecretText_SecretStrSubstNo_TemplateFromTextVariable_IsNotEmpty()
    // CLAIM: the template may come from a Text variable, not only a literal. Worth its own
    // test because a literal could in principle be resolved at compile time.
    var
        Secret: SecretText;
        Template: Text;
    begin
        Initialize();

        Template := 'built-from-a-variable';
        Secret := SecretStrSubstNo(Template);

        Assert.IsFalse(Secret.IsEmpty(), 'A template supplied from a Text variable must produce a non-empty secret');
    end;

    // -- Text variable assigns into SecretText -------------------------------

    [Test]
    procedure SecretText_AssignFromTextVariable_IsNotEmpty()
    // CLAIM: a Text VARIABLE assigns directly into a SecretText and carries its content.
    //
    // Note the asymmetry, measured with the compiler: `Secret := 'literal';` does NOT compile
    // (error AL0122, cannot implicitly convert 'Text' to 'SecretText'), while assigning from a
    // Text variable does. That is why this test uses a variable, and why no literal-assignment
    // test exists -- it could not be built.
    var
        Secret: SecretText;
        Plain: Text;
    begin
        Initialize();

        Plain := 'a-real-value-from-a-variable';
        Secret := Plain;

        Assert.IsFalse(Secret.IsEmpty(), 'A SecretText assigned from a non-blank Text variable must not be empty');
    end;

    [Test]
    procedure SecretText_AssignFromBlankTextVariable_IsEmpty()
    // CLAIM: assigning a blank Text variable leaves the secret empty -- '' is not content.
    // Pairs with the test above so neither passes against a constant.
    var
        Secret: SecretText;
        Plain: Text;
    begin
        Initialize();

        Plain := '';
        Secret := Plain;

        Assert.IsTrue(Secret.IsEmpty(), 'A SecretText assigned a blank Text variable must be empty');
    end;

    [Test]
    procedure SecretText_AssignFromSingleSpaceTextVariable_IsNotEmpty()
    // CLAIM: a single space is CONTENT, so the secret is not empty. This separates "empty means
    // zero-length" from "empty means blank/whitespace" -- an implementation that trimmed before
    // testing would fail here.
    var
        Secret: SecretText;
        Plain: Text;
    begin
        Initialize();

        Plain := ' ';
        Secret := Plain;

        Assert.IsFalse(Secret.IsEmpty(), 'A SecretText holding a single space must not report IsEmpty');
    end;

    // -- IsEmpty() -----------------------------------------------------------

    [Test]
    procedure SecretText_IsEmpty_Unassigned_ReturnsTrue()
    // CLAIM: a SecretText that was never assigned is empty.
    var
        Secret: SecretText;
    begin
        Initialize();

        Assert.IsTrue(Secret.IsEmpty(), 'An unassigned SecretText must report IsEmpty = true');
    end;

    [Test]
    procedure SecretText_IsEmpty_Reassigned_TracksLatestValue()
    // CLAIM: IsEmpty() reflects the CURRENT value across reassignment, in both directions and
    // within one test. A stub returning a constant fails one of the two assertions whichever
    // constant it returns -- this is the strongest anti-stub test in the file.
    var
        Secret: SecretText;
    begin
        Initialize();

        Secret := SecretStrSubstNo('populated');
        Assert.IsFalse(Secret.IsEmpty(), 'After assigning a populated secret, IsEmpty must be false');

        Secret := SecretStrSubstNo('');
        Assert.IsTrue(Secret.IsEmpty(), 'After assigning an empty secret, IsEmpty must be true again');
    end;

    // -- Composition: substituting secrets into a template -------------------

    [Test]
    procedure SecretText_SecretStrSubstNo_PopulatedArgument_ResultIsNotEmpty()
    // CLAIM: substituting a populated secret into a template yields a populated secret. This is
    // the connection-string case -- building a value out of a password.
    var
        Password: SecretText;
        Composed: SecretText;
    begin
        Initialize();

        Password := SecretStrSubstNo('p4ssw0rd');
        Composed := SecretStrSubstNo('pwd=%1', Password);

        Assert.IsFalse(Composed.IsEmpty(), 'Substituting a populated secret must yield a populated secret');
    end;

    [Test]
    procedure SecretText_SecretStrSubstNo_EmptyArgumentIntoBareTemplate_IsEmpty()
    // CLAIM: substituting an EMPTY secret into a bare '%1' template yields an empty secret.
    //
    // This is the test that proves the argument is genuinely interpolated: the template
    // contributes no literal characters of its own, so the result's emptiness can only come
    // from the substituted value. An implementation that ignored its arguments and returned the
    // template unchanged would produce '%1' here -- non-empty -- and fail.
    var
        Empty: SecretText;
        Composed: SecretText;
    begin
        Initialize();

        Composed := SecretStrSubstNo('%1', Empty);

        Assert.IsTrue(Composed.IsEmpty(), 'Substituting an empty secret into a bare %1 template must yield an empty secret');
    end;

    [Test]
    procedure SecretText_SecretStrSubstNo_EmptyArgumentWithLiteralTemplate_IsNotEmpty()
    // CLAIM: the same empty argument in a template that DOES carry literal text yields a
    // populated secret. Together with the test above this isolates where the content came
    // from -- the literal part of the template, not the argument.
    var
        Empty: SecretText;
        Composed: SecretText;
    begin
        Initialize();

        Composed := SecretStrSubstNo('pwd=%1', Empty);

        Assert.IsFalse(Composed.IsEmpty(), 'A template with literal text must yield a populated secret even when the argument is empty');
    end;

    [Test]
    procedure SecretText_SecretStrSubstNo_MultipleArguments_ResultIsNotEmpty()
    // CLAIM: the varargs form accepts more than one secret argument. Pins that the
    // multi-argument overload compiles and runs, which the single-argument tests do not reach.
    var
        User: SecretText;
        Password: SecretText;
        Composed: SecretText;
    begin
        Initialize();

        User := SecretStrSubstNo('admin');
        Password := SecretStrSubstNo('p4ssw0rd');
        Composed := SecretStrSubstNo('user=%1;pwd=%2', User, Password);

        Assert.IsFalse(Composed.IsEmpty(), 'SecretStrSubstNo with two secret arguments must produce a non-empty secret');
    end;

    // -- Secrecy survives copying and containers -----------------------------

    [Test]
    procedure SecretText_AssignToAnotherSecretText_PreservesContent()
    // CLAIM: assigning one SecretText to another copies the content -- the copy is populated.
    // Nothing may compare the two values (operator '=' is rejected for SecretText operands),
    // so IsEmpty() on the destination is the observable that the copy carried something.
    var
        Source: SecretText;
        Copy: SecretText;
    begin
        Initialize();

        Source := SecretStrSubstNo('copied-value');
        Copy := Source;

        Assert.IsFalse(Copy.IsEmpty(), 'A SecretText assigned from another must carry its content');
    end;

    [Test]
    procedure SecretText_AssignEmptyToAnotherSecretText_PreservesEmptiness()
    // CLAIM: copying an EMPTY secret over a populated one leaves the destination empty -- the
    // copy does not invent content, and does not silently keep the old value. The negative
    // direction of the copy pair.
    var
        Source: SecretText;
        Copy: SecretText;
    begin
        Initialize();

        Copy := SecretStrSubstNo('initially-populated');
        Copy := Source;

        Assert.IsTrue(Copy.IsEmpty(), 'Copying an empty SecretText must overwrite the destination with an empty secret');
    end;

    [Test]
    procedure SecretText_StoredInList_RoundTripsAsSecret()
    // CLAIM: a List of [SecretText] holds secrets and gives them back as SecretText -- the
    // container does not decay them into readable text. The retrieved element is still only
    // observable through IsEmpty().
    var
        Secrets: List of [SecretText];
        Stored: SecretText;
        Retrieved: SecretText;
    begin
        Initialize();

        Stored := SecretStrSubstNo('in-a-list');
        Secrets.Add(Stored);

        Assert.AreEqual(1, Secrets.Count(), 'The list must hold exactly the one secret added');

        Retrieved := Secrets.Get(1);
        Assert.IsFalse(Retrieved.IsEmpty(), 'A secret retrieved from a List must still carry its content');
    end;

    [Test]
    procedure SecretText_StoredInDictionary_RoundTripsAsSecret()
    // CLAIM: a Dictionary of [Text, SecretText] keys plain text to secrets, and the retrieved
    // value is still a SecretText carrying content. Pins that the secret survives a keyed
    // container as well as a sequential one.
    var
        Secrets: Dictionary of [Text, SecretText];
        Stored: SecretText;
        Retrieved: SecretText;
    begin
        Initialize();

        Stored := SecretStrSubstNo('in-a-dictionary');
        Secrets.Add('api-key', Stored);

        Assert.IsTrue(Secrets.ContainsKey('api-key'), 'The dictionary must contain the key the secret was stored under');

        Retrieved := Secrets.Get('api-key');
        Assert.IsFalse(Retrieved.IsEmpty(), 'A secret retrieved from a Dictionary must still carry its content');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
