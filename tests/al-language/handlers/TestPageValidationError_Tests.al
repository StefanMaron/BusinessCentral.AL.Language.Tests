// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfieldvalidationerrorcount-method
// Scope: in-scope
// Fixtures used: TestPage ErrTeardown Row (60796), TestPage ErrTeardown Card (60797), Assert (60021)
//
// What a REFUSED TestPage control write leaves behind on the control.
//
// `asserterror TestPage.<field>.SetValue(x)` is how a BC test asserts that a page refuses a
// value. The refusal is not only an exception: the control keeps a ledger of it, and
// `ValidationErrorCount()` / `GetValidationError(Index)` read that ledger AFTER the
// asserterror has already swallowed the exception. Microsoft's own tests rely on both halves
// — Tests-SINGLESERVER `Codeunit134614.TestRemoveSUPERPermissionsByUserAll` asserts
// `ValidationErrorCount() = 1` and compares `GetValidationError(1)` against the bare error
// text, and `UserRoleTest` asserts the trapped error text contains 'Validation error for
// Field' — but nothing in this corpus pinned either, so this codeunit does.
//
// The claims, one per [Test]:
//   1. a refused write records exactly one validation error on that control;
//   2. `GetValidationError(1)` answers the BARE error text, without the wrapper;
//   3. the exception the asserterror traps carries BOTH the wrapper and the bare text;
//   4. an ACCEPTED write records nothing and stores the value;
//   5. reading past the end of the ledger raises rather than answering an empty string.
//
// Claim 5 is the one with no prior measurement behind it. It is written because BC's own
// `NavTestField.ALGetValidationError(Index)` subtracts 1 from the AL index and catches
// `IndexOutOfRangeException` to rethrow its own out-of-bounds error — a catch that only makes
// sense if the underlying read really does raise. This test is what turns that reading into a
// measurement.
//
// Reuses the ErrTeardown fixtures rather than adding new ones: page 60797's NameCtl control
// already declares an OnValidate that raises when the row says so, which is exactly the
// refusal these claims need.

codeunit 60836 "TestPage ValidationError Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ValidateErrTok: Label 'Deliberate OnValidate failure for VAL-1', Locked = true;

    local procedure Initialize()
    var
        Row: Record "TestPage ErrTeardown Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed(No: Code[20]; FailOnValidate: Boolean)
    var
        Row: Record "TestPage ErrTeardown Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := 'Init';
        Row.FailOnGet := false;
        Row.FailOnValidate := FailOnValidate;
        Row.Insert();
    end;

    // Claim 1. A refused write records exactly one validation error on the control it was made
    // through — readable after the asserterror, which is the whole point of the ledger.
    // Asserting 1 rather than "> 0" is deliberate: one refused write is one error, and a count
    // that grew per retry would be a different behavior.
    [Test]
    procedure TestPage_SetValue_RefusedByOnValidate_RecordsOneValidationError()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        Assert.AreEqual(1, Card.NameCtl.ValidationErrorCount(),
            'A refused SetValue must leave exactly one validation error on the control');

        Card.Close();
    end;

    // Claim 2. GetValidationError(1) answers the BARE error text the AL raised — not the
    // "Validation error for Field: ..." wrapper the exception carries. Comparing for equality,
    // not containment, is what pins that the two are different strings.
    [Test]
    procedure TestPage_GetValidationError_RefusedByOnValidate_IsTheBareErrorText()
    var
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');

        Assert.AreEqual(ValidateErrTok, Card.NameCtl.GetValidationError(1),
            'GetValidationError(1) must answer the bare text the OnValidate raised');

        Card.Close();
    end;

    // Claim 3. The exception the asserterror traps is BC's validation wrapper around that same
    // bare text — both halves asserted, so a change to either is visible.
    [Test]
    procedure TestPage_SetValue_RefusedByOnValidate_RaisesTheValidationWrapper()
    var
        Card: TestPage "TestPage ErrTeardown Card";
        Trapped: Text;
    begin
        Initialize();
        Seed('VAL-1', true);

        Card.OpenView();
        Card.GoToKey('VAL-1');
        asserterror Card.NameCtl.SetValue('New Name');
        Trapped := GetLastErrorText();

        Assert.IsSubstring(Trapped, 'Validation error for Field');
        Assert.IsSubstring(Trapped, ValidateErrTok);

        Card.Close();
    end;

    // Claim 4, the negative direction: a write the page ACCEPTS records nothing, and the value
    // reaches the table. Without the second assertion this would pass against an implementation
    // that refused every write and simply never counted.
    [Test]
    procedure TestPage_SetValue_Accepted_RecordsNoValidationErrorAndStoresTheValue()
    var
        Row: Record "TestPage ErrTeardown Row";
        Card: TestPage "TestPage ErrTeardown Card";
    begin
        Initialize();
        Seed('VAL-OK', false);

        Card.OpenView();
        Card.GoToKey('VAL-OK');
        Card.NameCtl.SetValue('Accepted Name');

        Assert.AreEqual(0, Card.NameCtl.ValidationErrorCount(),
            'An accepted SetValue must leave no validation error on the control');

        Card.Close();

        Row.Get('VAL-OK');
        Assert.AreEqual('Accepted Name', Row.Name,
            'The accepted value must reach the backing table');
    end;

    // Claim 5. Reading past the end of the ledger raises rather than answering an empty string.
    // The count is asserted first so this is not a bare asserterror: the control genuinely has
    // no errors, and index 1 is genuinely past the end.
    [Test]
    procedure TestPage_GetValidationError_PastTheEnd_Raises()
    var
        Card: TestPage "TestPage ErrTeardown Card";
        Ignored: Text;
    begin
        Initialize();
        Seed('VAL-OK', false);

        Card.OpenView();
        Card.GoToKey('VAL-OK');

        Assert.AreEqual(0, Card.NameCtl.ValidationErrorCount(),
            'No write has been refused, so the ledger must be empty');

        asserterror Ignored := Card.NameCtl.GetValidationError(1);
        Assert.AreNotEqual('', GetLastErrorText(),
            'GetValidationError past the end must raise, not answer an empty string');

        Card.Close();
    end;
}
