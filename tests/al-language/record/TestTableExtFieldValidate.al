// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/field/devenv-onvalidate-field-trigger
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), ALT Triggered (60002), ALT Trigger Log (60003),
//   ALT Triggered Order Ext (60024), ALT Universal Validated Ext (60025)
//
// A tableextension can ADD fields that carry their own OnValidate trigger. That
// trigger is a first-class field trigger: Rec.Validate on the added field must run
// it, and direct assignment must not. This is a different mechanism from the
// modify() OnBefore/OnAfterValidate triggers (covered by TestTriggerDispatchOrder),
// which wrap around a BASE field's own OnValidate.

codeunit 60994 "Test TableExt Field Validate"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TableExtField_Validate_TriggerlessBaseTable_RunsOnValidate()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Universal."Entry No." := 301;
        Universal.Insert(false);
        Universal.Get(301);

        Universal.Validate("Ext Validated", 'Validated');

        TrigLog.SetRange(TriggerName, 'UNIVERSALEXTONVALIDATE');
        Assert.AreEqual(1, TrigLog.Count(), 'Validate on a tableextension-added field must run its OnValidate exactly once, even when the base table declares no field triggers');
        TrigLog.FindFirst();
        Assert.AreEqual('Validated', TrigLog.NewValue, 'the OnValidate trigger must observe the new value on Rec');
        Assert.AreEqual('', TrigLog.OldValue, 'the OnValidate trigger must observe the old value on xRec');
        Assert.AreEqual('Validated', Universal."Ext Validated", 'Validate must also assign the value');
    end;

    [Test]
    procedure TableExtField_Assign_DoesNotRunOnValidate()
    var
        Universal: Record "ALT Universal";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Universal."Entry No." := 302;
        Universal.Insert(false);
        Universal.Get(302);

        Universal."Ext Validated" := 'Assigned';

        Assert.AreEqual(0, TrigLog.Count(), 'direct assignment to a tableextension-added field must not run its OnValidate');
        Assert.AreEqual('Assigned', Universal."Ext Validated", 'direct assignment must still set the value');
    end;

    [Test]
    procedure TableExtField_Validate_BaseTableWithFieldTriggers_RunsOnValidate()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Triggered."Entry No." := 303;
        Triggered.Insert(false);
        ClearLog(); // Insert on ALT Triggered logs record triggers; isolate the Validate

        Triggered.Get(303);
        Triggered.Validate("Ext Validated", 'Validated');

        TrigLog.SetRange(TriggerName, 'TABLEEXTFIELDONVALIDATE');
        Assert.AreEqual(1, TrigLog.Count(), 'Validate on a tableextension-added field must run its OnValidate when the base table has its own field triggers');
        TrigLog.SetRange(TriggerName);
        TrigLog.SetRange(TriggerName, 'ONVALIDATE');
        Assert.AreEqual(0, TrigLog.Count(), 'validating the extension field must not run the base field''s OnValidate');
        Assert.AreEqual('Validated', Triggered."Ext Validated", 'Validate must also assign the value');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLog();
    end;

    local procedure ClearLog()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.DeleteAll(false);
    end;
}
