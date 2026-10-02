// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handlerfunctions-attribute
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// CLAIM: the name in [HandlerFunctions('...')] is matched against the handler procedure's
// name WITHOUT regard to case, the same way every other AL identifier is. A handler listed
// as 'hnccasehandler' or 'HNCCASEHANDLER' is bound to the procedure declared as
// HncCaseHandler, and the UI call inside the test reaches it instead of being refused as an
// unhandled UI. (A listed name that matches no procedure at all is refused at compile time
// with AL0499; that diagnostic is the reason a mismatch in case alone is worth pinning -- it
// is the one spelling difference the compiler lets through.)
//
// WHY EACH ARM IS BUILT THE WAY IT IS. Every positive arm asserts the handler's own side
// effect (its fire count and the reply it gave), so a test that merely did not fail cannot
// pass: with the handler unbound the Confirm is refused and the test fails outright, and a
// bound-but-wrong handler shows up in the counters. The neighbour arm lists the NO-replying
// handler in lower case while a YES-replying handler of the same kind sits beside it, so a
// binding that picked "some ConfirmHandler" or "the first one" gives a different reply and a
// different pair of counters than the one that picked the right procedure.

codeunit 69230 "Handler Name Case Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        YesFireCount: Integer;
        NoFireCount: Integer;
        MessageFireCount: Integer;
        LastQuestion: Text;
        LastMessage: Text;

    local procedure Initialize()
    begin
        YesFireCount := 0;
        NoFireCount := 0;
        MessageFireCount := 0;
        LastQuestion := '';
        LastMessage := '';
    end;

    [Test]
    [HandlerFunctions('hncyeshandler')]
    procedure HandlerName_AllLowerCase_BindsConfirmHandler()
    var
        Reply: Boolean;
    begin
        Initialize();

        Reply := Confirm('HNC lower case question?');

        Assert.IsTrue(Reply, 'the handler answers Yes, so a bound handler must make Confirm return true');
        Assert.AreEqual(1, YesFireCount, 'HncYesHandler must have fired exactly once when listed as hncyeshandler');
        Assert.AreEqual('HNC lower case question?', LastQuestion, 'the handler must have received the question the test raised');
    end;

    [Test]
    [HandlerFunctions('HNCYESHANDLER')]
    procedure HandlerName_AllUpperCase_BindsConfirmHandler()
    var
        Reply: Boolean;
    begin
        Initialize();

        Reply := Confirm('HNC upper case question?');

        Assert.IsTrue(Reply, 'the handler answers Yes, so a bound handler must make Confirm return true');
        Assert.AreEqual(1, YesFireCount, 'HncYesHandler must have fired exactly once when listed as HNCYESHANDLER');
        Assert.AreEqual('HNC upper case question?', LastQuestion, 'the handler must have received the question the test raised');
    end;

    [Test]
    [HandlerFunctions('HncYesHandler')]
    procedure HandlerName_ExactCase_BindsConfirmHandler()
    var
        Reply: Boolean;
    begin
        Initialize();

        Reply := Confirm('HNC exact case question?');

        Assert.IsTrue(Reply, 'the handler answers Yes, so a bound handler must make Confirm return true');
        Assert.AreEqual(1, YesFireCount, 'HncYesHandler must have fired exactly once when listed with its declared spelling');
    end;

    [Test]
    [HandlerFunctions('hncnohandler')]
    procedure HandlerName_LowerCase_BindsTheNamedHandlerNotItsNeighbour()
    var
        Reply: Boolean;
    begin
        Initialize();

        Reply := Confirm('HNC neighbour question?');

        Assert.IsFalse(Reply, 'hncnohandler names the handler that answers No, so Confirm must return false');
        Assert.AreEqual(1, NoFireCount, 'HncNoHandler must have fired exactly once');
        Assert.AreEqual(0, YesFireCount, 'HncYesHandler is not listed, so it must not have fired');
    end;

    [Test]
    [HandlerFunctions('hncmessagehandler,HNCYESHANDLER')]
    procedure HandlerNames_MixedCaseInOneAttribute_BindEveryListedHandler()
    var
        Reply: Boolean;
    begin
        Initialize();

        Message('HNC message text');
        Reply := Confirm('HNC mixed question?');

        Assert.AreEqual(1, MessageFireCount, 'HncMessageHandler must have fired once when listed as hncmessagehandler');
        Assert.AreEqual('HNC message text', LastMessage, 'the message handler must have received the message the test raised');
        Assert.IsTrue(Reply, 'HNCYESHANDLER names the handler that answers Yes');
        Assert.AreEqual(1, YesFireCount, 'HncYesHandler must have fired once when listed as HNCYESHANDLER');
        Assert.AreEqual(0, NoFireCount, 'HncNoHandler is not listed, so it must not have fired');
    end;

    [ConfirmHandler]
    procedure HncYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        YesFireCount += 1;
        LastQuestion := Question;
        Reply := true;
    end;

    [ConfirmHandler]
    procedure HncNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        NoFireCount += 1;
        LastQuestion := Question;
        Reply := false;
    end;

    [MessageHandler]
    procedure HncMessageHandler(Message: Text[1024])
    begin
        MessageFireCount += 1;
        LastMessage := Message;
    end;
}
