// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74003
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on TextBuilder: length, capacity, reuse
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74003 "LT P95 Clear TextBuilder"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearTextBuilder()
    var
        Observer: Codeunit "Probe Observer";
        Tx: TextBuilder;
        Tx2: TextBuilder;
        Tx3: TextBuilder;
    begin
        Tx.Append('hello');
        Tx.AppendLine('world');
        Observer.Observe('len_before', Format(Tx.Length()));
        Clear(Tx);
        Observer.Observe('len_after', Format(Tx.Length()));
        Observer.Observe('text_after', '[' + Tx.ToText() + ']');
        Observer.Observe('capacity_positive', Format(Tx.Capacity() > 0));
        Tx.Append('again');
        Observer.Observe('reuse', Tx.ToText());
        Tx2 := Tx;
        Clear(Tx);
        Observer.Observe('copy_after_clear', Format(Tx2.Length()) + '|' + Format(Tx.Length()));
        Tx3.Capacity(100);
        Clear(Tx3);
        Observer.Observe('capacity_cleared_positive', Format(Tx3.Capacity() > 0) + '|' + Format(Tx3.Capacity() = 100));

        Observer.Finish();
    end;

}
