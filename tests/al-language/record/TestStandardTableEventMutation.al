// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: ALT Fixture Cleanup (60001), ALT Standard Table Mut (60032)
// BC versions: 27.5+

codeunit 60238 "Test Standard Tbl Mut"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure StandardTable_OnAfterValidate_VarRecMutation_Propagates()
    var
        PaymentTerms: Record "Payment Terms" temporary;
    begin
        Initialize();
        PaymentTerms.Code := 'TMP';

        Assert.IsFalse(
            PaymentTerms."Calc. Pmt. Disc. on Cr. Memos",
            'Temporary Payment Terms record must start with the target field cleared');

        PaymentTerms.Validate(Description, 'MutationProbe');

        Assert.AreEqual('MutationProbe', PaymentTerms.Description, 'Validate must apply the new field value on the standard table record');
        Assert.IsTrue(
            PaymentTerms."Calc. Pmt. Disc. on Cr. Memos",
            'OnAfterValidateEvent on a standard table must be able to mutate var Rec and propagate that value back to the validated record');
    end;

    [Test]
    procedure StandardTable_OnAfterValidate_EmptyValue_NoOp()
    var
        PaymentTerms: Record "Payment Terms" temporary;
    begin
        Initialize();
        PaymentTerms.Code := 'TMP2';
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := false;

        PaymentTerms.Validate(Description, '');

        Assert.AreEqual('', PaymentTerms.Description, 'Validate with empty text must still complete on the standard table record');
        Assert.IsFalse(
            PaymentTerms."Calc. Pmt. Disc. on Cr. Memos",
            'Subscriber no-op direction must leave the unrelated field unchanged');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
