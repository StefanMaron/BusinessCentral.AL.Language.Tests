// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), enum LT P89 Color (74626)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74632 "LT P89 Is PromptMode"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsPromptMode() then
            R += 'PromptMode,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsExecutionMode() then
            R += 'ExecutionMode,';
        exit(R);
    end;

    [Test]
    procedure PromptMode_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: PromptMode;
        V: Variant;
    begin
        V := X; Observer.Observe('default', Flags(V));
        X := PromptMode::Prompt;
        V := X; Observer.Observe('prompt', Flags(V));
        Observer.Observe('prompt_format', Format(X));
        V := PromptMode::Prompt; Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;
}
