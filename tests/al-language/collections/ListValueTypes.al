// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74613
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List of [T] for value types: equality used by Contains/IndexOf/LastIndexOf/Remove for Decimal, Boolean, Date, Time, DateTime, Char, Guid, Option, Enum, BigInteger, Duration.
// BC versions: 29 (27 and 28 by CI)

codeunit 74613 "LT ClT List ValueTypes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Dec_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Decimal];
        D: Decimal;
    begin
        L.Add(1.5);
        L.Add(2);
        L.Add(0);
        L.Add(-0.000001);
        L.Add(1.50);
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('indexof 1.5', Format(L.IndexOf(1.5)));
        Observer.Observe('lastindexof 1.5', Format(L.LastIndexOf(1.5)));
        Observer.Observe('contains 2.0', Format(L.Contains(2.0)));
        Observer.Observe('contains int 2', Format(L.Contains(2)));
        Observer.Observe('contains 1.500001', Format(L.Contains(1.500001)));
        Observer.Observe('indexof -0.000001', Format(L.IndexOf(-0.000001)));
        D := 1 / 3;
        L.Add(D);
        Observer.Observe('contains 1/3', Format(L.Contains(1 / 3)));
        Observer.Observe('contains 0.333333', Format(L.Contains(0.333333)));
        Observer.Observe('get last', Format(L.Get(L.Count()), 0, 9));
        Observer.Expect('count', '5');
        Observer.Expect('indexof 1.5', '1');
        Observer.Expect('lastindexof 1.5', '5');
        Observer.Expect('contains 2.0', 'Yes');
        Observer.Expect('contains int 2', 'Yes');
        Observer.Expect('contains 1.500001', 'No');
        Observer.Expect('indexof -0.000001', '4');
        Observer.Expect('contains 1/3', 'Yes');
        Observer.Expect('contains 0.333333', 'No');
        Observer.Expect('get last', '0.333333333333333333');
        Observer.Verify();
    end;

    [Test]
    procedure Bool_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Boolean];
    begin
        L.Add(true);
        L.Add(false);
        L.Add(true);
        Observer.Observe('indexof true', Format(L.IndexOf(true)));
        Observer.Observe('lastindexof true', Format(L.LastIndexOf(true)));
        Observer.Observe('indexof false', Format(L.IndexOf(false)));
        Observer.Observe('remove false', Format(L.Remove(false)));
        Observer.Observe('contains false', Format(L.Contains(false)));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('indexof true', '1');
        Observer.Expect('lastindexof true', '3');
        Observer.Expect('indexof false', '2');
        Observer.Expect('remove false', 'Yes');
        Observer.Expect('contains false', 'No');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Date];
        Blank: Date;
    begin
        L.Add(DMY2Date(1, 2, 2020));
        L.Add(0D);
        L.Add(DMY2Date(31, 12, 9999));
        L.Add(DMY2Date(1, 2, 2020));
        Observer.Observe('indexof 2020-02-01', Format(L.IndexOf(DMY2Date(1, 2, 2020)), 0, 9));
        Observer.Observe('lastindexof 2020-02-01', Format(L.LastIndexOf(DMY2Date(1, 2, 2020))));
        Observer.Observe('contains 0D', Format(L.Contains(0D)));
        Observer.Observe('contains blank var', Format(L.Contains(Blank)));
        Observer.Observe('indexof max', Format(L.IndexOf(DMY2Date(31, 12, 9999))));
        Observer.Observe('contains other', Format(L.Contains(DMY2Date(2, 2, 2020))));
        Observer.Observe('get blank', Format(L.Get(2), 0, 9));
        Observer.Expect('indexof 2020-02-01', '1');
        Observer.Expect('lastindexof 2020-02-01', '4');
        Observer.Expect('contains 0D', 'Yes');
        Observer.Expect('contains blank var', 'Yes');
        Observer.Expect('indexof max', '3');
        Observer.Expect('contains other', 'No');
        Observer.Expect('get blank', '');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Time];
    begin
        L.Add(120000T);
        L.Add(0T);
        L.Add(235959.999T);
        Observer.Observe('indexof 12:00', Format(L.IndexOf(120000T)));
        Observer.Observe('contains 0T', Format(L.Contains(0T)));
        Observer.Observe('contains 235959.999', Format(L.Contains(235959.999T)));
        Observer.Observe('contains 235959.998', Format(L.Contains(235959.998T)));
        Observer.Observe('contains 000000.001', Format(L.Contains(000000.001T)));
        Observer.Expect('indexof 12:00', '1');
        Observer.Expect('contains 0T', 'Yes');
        Observer.Expect('contains 235959.999', 'Yes');
        Observer.Expect('contains 235959.998', 'No');
        Observer.Expect('contains 000000.001', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [DateTime];
        Blank: DateTime;
    begin
        L.Add(CreateDateTime(DMY2Date(1, 1, 2020), 100000T));
        L.Add(Blank);
        L.Add(CreateDateTime(DMY2Date(1, 1, 2020), 100000.001T));
        Observer.Observe('indexof same', Format(L.IndexOf(CreateDateTime(DMY2Date(1, 1, 2020), 100000T)), 0, 9));
        Observer.Observe('indexof +1ms', Format(L.IndexOf(CreateDateTime(DMY2Date(1, 1, 2020), 100000.001T))));
        Observer.Observe('contains 0DT', Format(L.Contains(0DT)));
        Observer.Observe('contains other day', Format(L.Contains(CreateDateTime(DMY2Date(2, 1, 2020), 100000T))));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('indexof same', '1');
        Observer.Expect('indexof +1ms', '3');
        Observer.Expect('contains 0DT', 'Yes');
        Observer.Expect('contains other day', 'No');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Char];
        C: Char;
    begin
        C := 'a';
        L.Add(C);
        C := 'A';
        L.Add(C);
        C := 0;
        L.Add(C);
        C := 'a';
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('indexof a', Format(L.IndexOf(C)));
        C := 'A';
        Observer.Observe('indexof A', Format(L.IndexOf(C)));
        C := 'b';
        Observer.Observe('contains b', Format(L.Contains(C)));
        C := 0;
        Observer.Observe('indexof char 0', Format(L.IndexOf(C)));
        Observer.Observe('get 1 as int', Format(L.Get(1)));
        Observer.Expect('count', '3');
        Observer.Expect('indexof a', '1');
        Observer.Expect('indexof A', '2');
        Observer.Expect('contains b', 'No');
        Observer.Expect('indexof char 0', '3');
        Observer.Expect('get 1 as int', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Guid];
        G1: Guid;
        G2: Guid;
        Blank: Guid;
    begin
        Evaluate(G1, '{11111111-2222-3333-4444-555555555555}');
        Evaluate(G2, '{11111111-2222-3333-4444-555555555556}');
        L.Add(G1);
        L.Add(Blank);
        L.Add(G2);
        Observer.Observe('indexof g1', Format(L.IndexOf(G1)));
        Observer.Observe('indexof g2', Format(L.IndexOf(G2)));
        Observer.Observe('indexof blank', Format(L.IndexOf(Blank)));
        Evaluate(G2, '{11111111-2222-3333-4444-555555555555}');
        Observer.Observe('same value other var', Format(L.IndexOf(G2)));
        Evaluate(G2, '{11111111-2222-3333-4444-55555555555A}');
        Observer.Observe('different', Format(L.Contains(G2)));
        Observer.Observe('get 1', Format(L.Get(1)));
        Observer.Observe('get 2', Format(L.Get(2)));
        Evaluate(G2, '{11111111-2222-3333-4444-555555555555}');
        Observer.Observe('uppercase vs lowercase parse', Format(L.Contains(G2)));
        Observer.Expect('indexof g1', '1');
        Observer.Expect('indexof g2', '3');
        Observer.Expect('indexof blank', '2');
        Observer.Expect('same value other var', '1');
        Observer.Expect('different', 'No');
        Observer.Expect('get 1', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('get 2', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('uppercase vs lowercase parse', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BigInt_Duration_Equality()
    var
        Observer: Codeunit "Probe Observer";
        LB: List of [BigInteger];
        LD: List of [Duration];
        LI: List of [Integer];
        B: BigInteger;
    begin
        B := 3000000;
        B := B * 1000;
        LB.Add(B);
        LB.Add(1);
        Observer.Observe('big indexof', Format(LB.IndexOf(B)));
        Observer.Observe('big contains int 1', Format(LB.Contains(1)));
        LD.Add(1000);
        LD.Add(0);
        Observer.Observe('duration contains 1000', Format(LD.Contains(1000)));
        Observer.Observe('duration indexof 0', Format(LD.IndexOf(0)));
        LI.Add(2147483647);
        LI.Add(-2147483647);
        Observer.Observe('int max indexof', Format(LI.IndexOf(2147483647)));
        Observer.Observe('int min+1 indexof', Format(LI.IndexOf(-2147483647)));
        Observer.Expect('big indexof', '1');
        Observer.Expect('big contains int 1', 'Yes');
        Observer.Expect('duration contains 1000', 'Yes');
        Observer.Expect('duration indexof 0', '2');
        Observer.Expect('int max indexof', '1');
        Observer.Expect('int min+1 indexof', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Equality()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Enum "LT ClT Color"];
        C: Enum "LT ClT Color";
        Idx: Integer;
    begin
        L.Add(Enum::"LT ClT Color"::Blue);
        L.Add(Enum::"LT ClT Color"::Red);
        L.Add(Enum::"LT ClT Color"::Blue);
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('indexof Red', Format(L.IndexOf(Enum::"LT ClT Color"::Red)));
        Observer.Observe('lastindexof Blue', Format(L.LastIndexOf(Enum::"LT ClT Color"::Blue)));
        Observer.Observe('contains Green', Format(L.Contains(Enum::"LT ClT Color"::Green)));
        C := Enum::"LT ClT Color".FromInteger(5);
        Observer.Observe('contains FromInteger(5)', Format(L.Contains(C)));
        C := Enum::"LT ClT Color".FromInteger(0);
        Observer.Observe('contains default (Red)', Format(L.Contains(C)));
        Observer.Observe('get 1 format', Format(L.Get(1)));
        Observer.Observe('get 1 ordinal', Format(L.Get(1).AsInteger()));
        Observer.Observe('remove Blue', Format(L.Remove(Enum::"LT ClT Color"::Blue)));
        Observer.Observe('count after', Format(L.Count()));
        Idx := L.IndexOf(Enum::"LT ClT Color"::Blue);
        Observer.Observe('indexof Blue after', Format(Idx));
        Observer.Expect('count', '3');
        Observer.Expect('indexof Red', '2');
        Observer.Expect('lastindexof Blue', '3');
        Observer.Expect('contains Green', 'No');
        Observer.Expect('contains FromInteger(5)', 'Yes');
        Observer.Expect('contains default (Red)', 'Yes');
        Observer.Expect('get 1 format', 'Blue Caption');
        Observer.Expect('get 1 ordinal', '5');
        Observer.Expect('remove Blue', 'Yes');
        Observer.Expect('count after', '2');
        Observer.Expect('indexof Blue after', '2');
        Observer.Verify();
    end;
}
