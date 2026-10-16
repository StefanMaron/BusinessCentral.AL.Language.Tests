// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74002
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on List, Dictionary, nested collections and the errors after a Clear
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 74002 "LT P95 Clear Collections 2"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearCollections2()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        D: Dictionary of [Integer, Text];
        Nest: Dictionary of [Text, List of [Integer]];
        Inner: List of [Integer];
        LL: List of [Integer];
    begin
        L.Add('a');
        L.Add('b');
        D.Add(1, 'x');
        D.Add(2, 'y');
        Nest.Add('k', Inner);
        Inner.Add(5);
        Clear(L);
        Clear(D);
        Observer.Observe('list_count', Format(L.Count()));
        Observer.Observe('dict_count', Format(D.Count()));
        Observer.Observe('dict_contains', Format(D.ContainsKey(1)));
        Observer.Observe('dict_keys', Format(D.Keys().Count()));
        asserterror Observer.Observe('list_get', L.Get(1));
        Observer.ObserveError('list_get');
        asserterror Observer.Observe('dict_get', D.Get(1));
        Observer.ObserveError('dict_get');
        L.Add('c');
        D.Add(1, 'z');
        Observer.Observe('list_reuse', L.Get(1));
        Observer.Observe('dict_reuse', D.Get(1));
        Clear(Nest);
        Observer.Observe('nested_count', Format(Nest.Count()));
        Observer.Observe('inner_untouched', Format(Inner.Count()));
        Clear(Inner);
        Observer.Observe('inner_after', Format(Inner.Count()));
        Clear(LL);
        Observer.Observe('empty_clear', Format(LL.Count()));

        Observer.Finish();
    end;

}
