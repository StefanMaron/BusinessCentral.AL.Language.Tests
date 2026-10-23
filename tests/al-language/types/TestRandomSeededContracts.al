// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-random-function
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-randomize-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68380
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the numbers Random gives after Randomize(seed). They are the numbers of .NET's legacy generator
// (System.Random(seed): Knuth's subtractive generator), where Random(N) is Next(N) + 1:
//  - the same seed gives the same sequence; a negative seed gives the sequence of its absolute value
//    (-1 as 1); the seeds 0, 2147483647 and -2147483647 give one and the same sequence;
//  - Random(0) answers 1, a negative bound acts as its absolute value, Random(1) answers 1;
//  - Random(-2147483648) raises "Arithmetic operation resulted in an overflow." / AL:Overflow;
//  - Randomize() with no seed and Random without Randomize give numbers in 1..N that no test can predict.
// Writer RJ (al-runtime-rs ADR-053): Randomize(7) in one test, then Random in the next test of the same test codeunit (default TestIsolation of
//   the test runner): does the generator go on with the sequence of seed 7 (39 872 5 | 52262 ...)?
// BC versions: 27.5

codeunit 68380 "Probe Random Seeded"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Sequence(Seed: Integer): Text
    var
        Result: Text;
        Index: Integer;
    begin
        Randomize(Seed);
        Result := Format(Random(100)) + ' ' + Format(Random(1000)) + ' ' + Format(Random(7)) + ' |';
        for Index := 1 to 8 do
            Result += ' ' + Format(Random(1000000));
        exit(Result);
    end;

    [Test]
    procedure Randomize_Seed_GivesTheNetLegacySequence()
    begin
        Assert.AreEqual('25 111 4 | 771605 657519 432783 354084 943863 101267 642456 28637', Sequence(1), 'seed 1');
        Assert.AreEqual('67 141 1 | 522765 168435 262593 724409 512923 173652 761251 234589', Sequence(42), 'seed 42');
        Assert.AreEqual('39 872 5 | 52262 366434 676170 42424 953969 843567 854963 449020', Sequence(7), 'seed 7');
        Assert.AreEqual('39 872 5 | 52262 366434 676170 42424 953969 843567 854963 449020', Sequence(7), 'seed 7 again');
    end;

    [Test]
    procedure Randomize_NegativeSeed_IsItsAbsoluteValue_AndSomeSeedsCoincide()
    begin
        Assert.AreEqual(Sequence(1), Sequence(-1), 'seed -1 is seed 1');
        Assert.AreEqual('73 818 6 | 558162 206034 558885 906028 442178 977550 273705 291907', Sequence(0), 'seed 0');
        Assert.AreEqual(Sequence(0), Sequence(2147483647), 'seed 2147483647 is seed 0');
        Assert.AreEqual(Sequence(0), Sequence(-2147483647), 'seed -2147483647 is seed 0');
    end;

    [Test]
    procedure Random_ZeroAndNegativeBounds()
    var
        Zeros: Text;
        Negatives: Text;
        Positives: Text;
        Index: Integer;
    begin
        Randomize(5);
        for Index := 1 to 3 do
            Zeros += Format(Random(0)) + ' ';
        Assert.AreEqual('1 1 1 ', Zeros, 'Random(0)');

        Randomize(5);
        for Index := 1 to 6 do
            Negatives += Format(Random(-5)) + ' ';
        Randomize(5);
        for Index := 1 to 6 do
            Positives += Format(Random(5)) + ' ';
        Assert.AreEqual('2 2 2 4 3 5 ', Positives, 'Random(5)');
        Assert.AreEqual(Positives, Negatives, 'Random(-5) is Random(5)');

        Randomize(5);
        Assert.AreEqual('1 1 1', Format(Random(1)) + ' ' + Format(Random(1)) + ' ' + Format(Random(1)), 'Random(1)');
        Randomize(5);
        Assert.AreEqual('726643701 610783966 564707974', Format(Random(2147483647)) + ' ' + Format(Random(2147483647)) + ' ' + Format(Random(2147483647)), 'Random(2147483647)');
    end;

    [Test]
    procedure Random_SmallestInteger_Overflows()
    var
        Value: Integer;
    begin
        asserterror Value := Random(-2147483647 - 1);

        Assert.AreEqual('Arithmetic operation resulted in an overflow.', GetLastErrorText(), 'text');
        Assert.AreEqual('AL:Overflow', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Random_WithoutASeed_StaysInTheRange()
    var
        Value: Integer;
        Index: Integer;
    begin
        Randomize();
        for Index := 1 to 50 do begin
            Value := Random(10);
            Assert.IsTrue((Value >= 1) and (Value <= 10), 'in 1..10');
        end;
    end;

    // ---- Writer RJ: the seed of one test and Random in the next test of this codeunit. The two tests must stay adjacent and in this order. ----

    [Test]
    procedure RJ_Randomize_Seed7_InOneTest()
    begin
        Randomize(7);
        Assert.AreEqual(39, Random(100), 'first number of seed 7');
    end;

    [Test]
    procedure RJ_Randomize_Seed7_RandomInTheNextTest()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: Text;
    begin
        Numbers := Format(Random(1000)) + ' ' + Format(Random(7)) + ' ' + Format(Random(1000000));
        Observer.Observe('numbers', Numbers);
        Observer.Observe('go on with seed 7', Format(Numbers = '872 5 52262'));
        Observer.Finish();
    end;
}
