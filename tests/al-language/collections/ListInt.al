// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: LT ClT Fixtures not needed (self-contained codeunit 74610)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List of [Integer]: Add, Count, Get (two forms), Set, Insert, IndexOf, LastIndexOf, Contains, Remove, RemoveAt, RemoveRange, GetRange, Reverse, ToArray, return values.
// BC versions: 29 (27 and 28 by CI)

codeunit 74610 "LT ClT List Int"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Join(L: List of [Integer]): Text
    var
        i: Integer;
        R: Text;
    begin
        for i := 1 to L.Count() do begin
            if i > 1 then
                R += ',';
            R += Format(L.Get(i));
        end;
        exit('[' + R + ']');
    end;

    local procedure Make(var L: List of [Integer])
    begin
        L.Add(10);
        L.Add(20);
        L.Add(30);
        L.Add(20);
        L.Add(40);
    end;

    [Test]
    procedure Int_AddCountGet()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        V: Integer;
        B: Boolean;
    begin
        Observer.Observe('empty count', Format(L.Count()));
        Make(L);
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('get1', Format(L.Get(1)));
        Observer.Observe('get5', Format(L.Get(5)));
        B := L.Get(2, V);
        Observer.Observe('get out form ret', Format(B));
        Observer.Observe('get out form val', Format(V));
        V := -1;
        B := L.Get(6, V);
        Observer.Observe('get out of range ret', Format(B));
        Observer.Observe('get out of range val', Format(V));
        B := L.Get(0, V);
        Observer.Observe('get 0 ret', Format(B));
        Observer.Observe('get 0 val', Format(V));
        B := L.Get(-3, V);
        Observer.Observe('get neg ret', Format(B));
        Observer.Observe('list', Join(L));
        Observer.Expect('empty count', '0');
        Observer.Expect('count', '5');
        Observer.Expect('get1', '10');
        Observer.Expect('get5', '40');
        Observer.Expect('get out form ret', 'Yes');
        Observer.Expect('get out form val', '20');
        Observer.Expect('get out of range ret', 'No');
        Observer.Expect('get out of range val', '-1');
        Observer.Expect('get 0 ret', 'No');
        Observer.Expect('get 0 val', '-1');
        Observer.Expect('get neg ret', 'No');
        Observer.Expect('list', '[10,20,30,20,40]');
        Observer.Verify();
    end;

    [Test]
    procedure Int_IndexOfContains()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Empty: List of [Integer];
    begin
        Make(L);
        Observer.Observe('indexof 20', Format(L.IndexOf(20)));
        Observer.Observe('lastindexof 20', Format(L.LastIndexOf(20)));
        Observer.Observe('indexof 10', Format(L.IndexOf(10)));
        Observer.Observe('lastindexof 10', Format(L.LastIndexOf(10)));
        Observer.Observe('indexof missing', Format(L.IndexOf(99)));
        Observer.Observe('lastindexof missing', Format(L.LastIndexOf(99)));
        Observer.Observe('contains 30', Format(L.Contains(30)));
        Observer.Observe('contains 31', Format(L.Contains(31)));
        Observer.Observe('contains 0', Format(L.Contains(0)));
        Observer.Observe('empty indexof', Format(Empty.IndexOf(0)));
        Observer.Observe('empty lastindexof', Format(Empty.LastIndexOf(0)));
        Observer.Observe('empty contains', Format(Empty.Contains(0)));
        Observer.Expect('indexof 20', '2');
        Observer.Expect('lastindexof 20', '4');
        Observer.Expect('indexof 10', '1');
        Observer.Expect('lastindexof 10', '1');
        Observer.Expect('indexof missing', '0');
        Observer.Expect('lastindexof missing', '0');
        Observer.Expect('contains 30', 'Yes');
        Observer.Expect('contains 31', 'No');
        Observer.Expect('contains 0', 'No');
        Observer.Expect('empty indexof', '0');
        Observer.Expect('empty lastindexof', '0');
        Observer.Expect('empty contains', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Int_SetInsert()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        B: Boolean;
    begin
        Make(L);
        B := L.Set(1, 11);
        Observer.Observe('set ret', Format(B));
        Observer.Observe('after set', Join(L));
        B := L.Insert(1, 5);
        Observer.Observe('insert front ret', Format(B));
        Observer.Observe('after insert front', Join(L));
        B := L.Insert(L.Count() + 1, 99);
        Observer.Observe('insert end ret', Format(B));
        Observer.Observe('after insert end', Join(L));
        B := L.Insert(4, 77);
        Observer.Observe('insert middle ret', Format(B));
        Observer.Observe('after insert middle', Join(L));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('set ret', 'Yes');
        Observer.Expect('after set', '[11,20,30,20,40]');
        Observer.Expect('insert front ret', 'Yes');
        Observer.Expect('after insert front', '[5,11,20,30,20,40]');
        Observer.Expect('insert end ret', 'Yes');
        Observer.Expect('after insert end', '[5,11,20,30,20,40,99]');
        Observer.Expect('insert middle ret', 'Yes');
        Observer.Expect('after insert middle', '[5,11,20,77,30,20,40,99]');
        Observer.Expect('count', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Int_Remove()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        B: Boolean;
    begin
        Make(L);
        B := L.Remove(20);
        Observer.Observe('remove 20 ret', Format(B));
        Observer.Observe('after remove 20 (first only?)', Join(L));
        B := L.Remove(99);
        Observer.Observe('remove missing ret', Format(B));
        Observer.Observe('after remove missing', Join(L));
        B := L.RemoveAt(1);
        Observer.Observe('removeat 1 ret', Format(B));
        Observer.Observe('after removeat 1', Join(L));
        B := L.RemoveAt(L.Count());
        Observer.Observe('removeat last ret', Format(B));
        Observer.Observe('after removeat last', Join(L));
        B := L.RemoveAt(10);
        Observer.Observe('removeat 10 ret', Format(B));
        B := L.RemoveAt(0);
        Observer.Observe('removeat 0 ret', Format(B));
        Observer.Observe('after bad removeat', Join(L));
        Observer.Expect('remove 20 ret', 'Yes');
        Observer.Expect('after remove 20 (first only?)', '[10,30,20,40]');
        Observer.Expect('remove missing ret', 'No');
        Observer.Expect('after remove missing', '[10,30,20,40]');
        Observer.Expect('removeat 1 ret', 'Yes');
        Observer.Expect('after removeat 1', '[30,20,40]');
        Observer.Expect('removeat last ret', 'Yes');
        Observer.Expect('after removeat last', '[30,20]');
        Observer.Expect('removeat 10 ret', 'No');
        Observer.Expect('removeat 0 ret', 'No');
        Observer.Expect('after bad removeat', '[30,20]');
        Observer.Verify();
    end;

    [Test]
    procedure Int_RemoveRange()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        B: Boolean;
    begin
        Make(L);
        B := L.RemoveRange(2, 2);
        Observer.Observe('removerange 2,2 ret', Format(B));
        Observer.Observe('after', Join(L));
        Clear(L);
        Make(L);
        B := L.RemoveRange(1, 0);
        Observer.Observe('removerange 1,0 ret', Format(B));
        Observer.Observe('after count0', Join(L));
        B := L.RemoveRange(1, 5);
        Observer.Observe('removerange 1,5 ret', Format(B));
        Observer.Observe('after all', Join(L));
        Clear(L);
        Make(L);
        B := L.RemoveRange(4, 3);
        Observer.Observe('removerange 4,3 (too many) ret', Format(B));
        Observer.Observe('after too many', Join(L));
        B := L.RemoveRange(6, 1);
        Observer.Observe('removerange 6,1 ret', Format(B));
        B := L.RemoveRange(0, 1);
        Observer.Observe('removerange 0,1 ret', Format(B));
        B := L.RemoveRange(1, -1);
        Observer.Observe('removerange 1,-1 ret', Format(B));
        Observer.Observe('after bad', Join(L));
        Observer.Expect('removerange 2,2 ret', 'Yes');
        Observer.Expect('after', '[10,20,40]');
        Observer.Expect('removerange 1,0 ret', 'Yes');
        Observer.Expect('after count0', '[10,20,30,20,40]');
        Observer.Expect('removerange 1,5 ret', 'Yes');
        Observer.Expect('after all', '[]');
        Observer.Expect('removerange 4,3 (too many) ret', 'No');
        Observer.Expect('after too many', '[10,20,30,20,40]');
        Observer.Expect('removerange 6,1 ret', 'No');
        Observer.Expect('removerange 0,1 ret', 'No');
        Observer.Expect('removerange 1,-1 ret', 'No');
        Observer.Expect('after bad', '[10,20,30,20,40]');
        Observer.Verify();
    end;

    [Test]
    procedure Int_GetRange()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        R: List of [Integer];
    begin
        Make(L);
        R := L.GetRange(2, 3);
        Observer.Observe('getrange 2,3', Join(R));
        R := L.GetRange(1, 0);
        Observer.Observe('getrange 1,0 count', Format(R.Count()));
        R := L.GetRange(1, 5);
        Observer.Observe('getrange 1,5', Join(R));
        R := L.GetRange(5, 1);
        Observer.Observe('getrange 5,1', Join(R));
        R.Add(1);
        Observer.Observe('range is a copy: source', Join(L));
        Observer.Expect('getrange 2,3', '[20,30,20]');
        Observer.Expect('getrange 1,0 count', '0');
        Observer.Expect('getrange 1,5', '[10,20,30,20,40]');
        Observer.Expect('getrange 5,1', '[40]');
        Observer.Expect('range is a copy: source', '[10,20,30,20,40]');
        Observer.Verify();
    end;

    [Test]
    procedure Int_Reverse()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Empty: List of [Integer];
    begin
        Make(L);
        L.Reverse();
        Observer.Observe('reverse', Join(L));
        Empty.Reverse();
        Observer.Observe('reverse empty', Join(Empty));
        Observer.Expect('reverse', '[40,20,30,20,10]');
        Observer.Expect('reverse empty', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Int_ClearAndAssignNew()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
    begin
        Make(L);
        Clear(L);
        Observer.Observe('count after Clear()', Format(L.Count()));
        L.Add(1);
        Observer.Observe('add after clear', Join(L));
        Observer.Expect('count after Clear()', '0');
        Observer.Expect('add after clear', '[1]');
        Observer.Verify();
    end;
}
