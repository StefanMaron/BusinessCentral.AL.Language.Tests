// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Enum Var Row (60717), Test Page Enum Var Kind (60718),
//   Test Page Enum Var Modal (60719), Assert (60021)
//
// Page.RunModal() on a page whose layout binds a control to a page GLOBAL VARIABLE of type
// Enum. This is distinct from TestPageEnumField_Tests.al (an Enum-typed RECORD FIELD control),
// and from TestPageModalHandler_ModalVarsPage.al / TestPageVariableControl_Page.al (page-global
// variable controls, but typed Text / Option, not Enum) — the combination of "page-global
// variable" AND "Enum" is what this suite pins.

codeunit 60720 "Test Page Enum Var Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Enum Var Row";
    begin
        Row.DeleteAll();
    end;

    // Positive: RunModal materialises the page at all (an enum-bound page-global control must
    // not block form construction), the [ModalPageHandler] runs, and the handler's SetValue
    // reaches the page's own OnValidate trigger.
    [Test]
    [HandlerFunctions('KindHandler')]
    procedure RunModal_EnumGlobalControl_HandlerSetsValueAndOnValidateSeesIt()
    var
        Echo: Record "Test Page Enum Var Row";
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Modal.RunModal();

        Assert.IsTrue(Echo.Get('KIND'),
            'the [ModalPageHandler] must have run and OnValidate must have fired');
    end;

    // Positive, concrete value: after RunModal returns, the page variable itself holds the
    // SPECIFIC member the handler chose BY NAME ('Block', ordinal 1) — not the field's zero
    // default, and not some other member. Proves the control's real current value (not a
    // stashed/default one) round-trips through the page.
    //
    // NOTE: SetValue is deliberately driven by MEMBER NAME here, not by the enum's declared
    // Caption ('Blocks') — TestPage caption-based resolution for an Enum-typed control (as
    // opposed to Option's control-level OptionCaption property) is a separate, not yet proven,
    // surface; see the runner repo's tracking issue for that gap. This suite's claim is
    // narrower: RunModal materialises the page and the real value round-trips.
    [Test]
    [HandlerFunctions('KindHandler')]
    procedure RunModal_EnumGlobalControl_ProcedureReadsBackTheHandlerChosenValue()
    var
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Modal.RunModal();

        Assert.AreEqual(1, Modal.GetSelectedKindOrdinal(),
            'the page variable must hold the handler-set member (Blocks = 1), not the default (Fields = 0)');
    end;

    // Negative / control: WITHOUT RunModal, the same page variable's procedure still works and
    // reads the declared default. This is the exact split the original report described — the
    // enum itself is always compiled and reachable; only FORM MATERIALISATION can regress. If
    // this test fails too, the defect is unrelated to page materialisation.
    [Test]
    procedure GetSelectedKindOrdinal_WithoutRunModal_ReadsTheDeclaredDefault()
    var
        Modal: Page "Test Page Enum Var Modal";
    begin
        Initialize();

        Assert.AreEqual(0, Modal.GetSelectedKindOrdinal(),
            'without RunModal the page variable never left its declared default (Field = 0)');
    end;

    [ModalPageHandler]
    procedure KindHandler(var Modal: TestPage "Test Page Enum Var Modal")
    begin
        Modal.KindSelector.SetValue('Block');
        Modal.OK().Invoke();
    end;
}
