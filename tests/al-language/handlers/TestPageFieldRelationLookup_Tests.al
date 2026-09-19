// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Related (60563), TRL Related List (60564), TRL Host (60565),
//   TRL Card (60566); shared Assert (60021)
//
/// <summary>
/// Pins what a TestPage field's Lookup() does when the ONLY thing that can resolve the lookup
/// is the source table field's TableRelation -- neither the page control nor the table field
/// declares an OnLookup trigger of any kind.
///
/// AL puts a lookup in three places, and this suite is about the third. A page control can
/// declare trigger OnLookup(var Text: Text): Boolean; a table field can declare the unrelated
/// parameterless trigger OnLookup(); and a table field can declare neither and instead carry a
/// TableRelation, which is what the overwhelming majority of Base Application fields do. The
/// first two are already pinned by "TFL Tests" (60316). This suite pins the third.
///
/// The claims, each in its own test:
///   - Lookup() on a control whose field declares only a TableRelation opens the RELATED
///     table's LookupPageId page modally, so a declared [ModalPageHandler] for that page runs.
///   - The row the handler leaves selected is written back into the host field, which is how a
///     lookup differs from merely opening a page.
///   - A handler that CANCELS leaves the host field unchanged -- the write-back is conditional
///     on the outcome, not unconditional.
///   - A field with neither a trigger nor a TableRelation has nothing to resolve, and Lookup()
///     then COMPLETES WITHOUT ERROR, leaving the field exactly as it was.
///
/// The fourth is the one that keeps the first three honest. An implementation that opened a
/// page for every triggerless lookup -- the first page it found, or the host's own -- fails
/// it, because a page that opened with no handler declared would raise.
///
/// That fourth claim was measured rather than assumed, and the first version of this suite got
/// it wrong. It asserted that BC RAISES for that shape; all eight cloud legs answered
/// "An error was expected inside an ASSERTERROR statement" on run 35445556865, identically on
/// 27.0, 27.3, 27.5, 28.0, 28.1, 28.2, 28.3 and 28.4. So BC does nothing at all here -- no
/// error, no page -- and the assertion now says that. The other five claims below passed on
/// all eight legs of that same run.
/// </summary>
codeunit 60569 "TRL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerRan: Boolean;

    local procedure OpenOn(var Card: TestPage "TRL Card")
    var
        Host: Record "TRL Host";
        Related: Record "TRL Related";
    begin
        HandlerRan := false;

        Related.DeleteAll();
        Related.Init();
        Related."Code" := 'REL-A';
        Related.Descr := 'Alpha';
        Related.Insert();
        Related.Init();
        Related."Code" := 'REL-B';
        Related.Descr := 'Beta';
        Related.Insert();

        Host.DeleteAll();
        Host.Init();
        Host."No." := 'H1';
        Host.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Host);
    end;

    // CLAIM: the lookup opens the related table's LookupPageId page, modally, so the declared
    // [ModalPageHandler] for THAT page runs. Nothing in the AL under test names the page --
    // the only route to it is "Related Code"'s TableRelation to "TRL Related", whose
    // LookupPageId is "TRL Related List". A handler that never ran leaves HandlerRan false.
    [Test]
    [HandlerFunctions('RelatedListHandler')]
    procedure Lookup_TableRelationOnly_OpensTheRelatedTablesLookupPage()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);

        Card."Related Code".Lookup();

        Assert.IsTrue(HandlerRan,
            'a lookup on a field whose only lookup source is a TableRelation must open the related table''s LookupPageId page modally');
        Card.Close();
    end;

    // CLAIM: the row the handler leaves selected is written back into the host field. This is
    // what makes it a LOOKUP rather than just an open: the handler moves to REL-B and presses
    // OK, and the host control afterwards reads REL-B. Asserting the specific value rather
    // than "not blank" is what distinguishes a real write-back from a page that happened to
    // stamp something.
    [Test]
    [HandlerFunctions('RelatedListPicksBHandler')]
    procedure Lookup_TableRelationOnly_WritesTheSelectedRowBack()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);

        Card."Related Code".Lookup();

        Assert.AreEqual('REL-B', Card."Related Code".Value,
            'the row the lookup page''s handler left selected must be written back into the host field');
        Card.Close();
    end;

    // CLAIM: the write-back is conditional on the handler's outcome. A handler that CANCELS
    // moves to REL-B exactly as the previous test's does, and the host field must still be
    // blank afterwards -- so an implementation that assigns unconditionally passes the test
    // above and fails this one.
    [Test]
    [HandlerFunctions('RelatedListCancelsHandler')]
    procedure Lookup_TableRelationOnly_CancelLeavesTheFieldUnchanged()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);

        Card."Related Code".Lookup();

        Assert.AreEqual('', Card."Related Code".Value,
            'a cancelled lookup must leave the host field unchanged, whatever row the handler moved to');
        Card.Close();
    end;

    // CLAIM: a field with no trigger AND no TableRelation has nothing to resolve a lookup
    // from, and Lookup() then completes without error, having changed nothing. "Plain Code" is
    // "Related Code" minus exactly one property, so this separates "the relation was followed"
    // from "a page was opened for any triggerless lookup".
    //
    // No handler is declared here, deliberately, and that is what carries the "no page opened"
    // half: a modal page opening with no [ModalPageHandler] bound raises on real BC, so if this
    // shape DID open something the call would fail rather than reach the assertion below. The
    // assertion then carries the other half -- that the field is untouched.
    //
    // Measured, not assumed: this test first asserted that BC RAISES here, and all eight cloud
    // legs disagreed (run 35445556865). BC's answer is silence.
    [Test]
    procedure Lookup_NoTriggerAndNoTableRelation_DoesNothing()
    var
        Card: TestPage "TRL Card";
    begin
        OpenOn(Card);
        Card."Plain Code".SetValue('KEEP');

        // No asserterror: this must not raise. An implementation that opened a page here fails
        // on the unhandled-UI refusal before reaching the assertion.
        Card."Plain Code".Lookup();

        Assert.AreEqual('KEEP', Card."Plain Code".Value,
            'a lookup with neither an OnLookup trigger nor a TableRelation must leave the field exactly as it was');
        Card.Close();
    end;

    [ModalPageHandler]
    procedure RelatedListHandler(var Modal: TestPage "TRL Related List")
    begin
        HandlerRan := true;
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RelatedListPicksBHandler(var Modal: TestPage "TRL Related List")
    begin
        HandlerRan := true;
        Modal.GoToKey('REL-B');
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RelatedListCancelsHandler(var Modal: TestPage "TRL Related List")
    begin
        HandlerRan := true;
        Modal.GoToKey('REL-B');
        Modal.Cancel().Invoke();
    end;
}
