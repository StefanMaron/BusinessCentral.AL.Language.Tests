// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-function
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68440
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins Evaluate into a DateFormula for inputs the other date formula tests leave open, with what Format
// prints back and what CalcDate(formula, 2024-01-31) gives (XML date format):
//  - lower case letters are read (1d is 1D); angle brackets and white space are ignored (<-WD1>, 1 D,
//    " 1D "); "< >" is the empty formula; a sign in front is kept (+1D);
//  - a bare letter without a number is a formula (D1, WD1) but "D" and "<D>" are not; 1X, 1.5D, 1 alone,
//    LW and two parts without a sign (1D1W) are not;
//  - CalcDate with the empty formula on the undefined date raises "You cannot base a date calculation on
//    an undefined date." followed by the date and the formula; on a real date it gives the date.
// BC versions: 27.5

codeunit 68440 "Probe DateFormula Leftovers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Outcome(Input: Text): Text
    var
        Formula: DateFormula;
    begin
        if not Evaluate(Formula, Input) then
            exit('false');
        exit('true [' + Format(Formula) + '] ' + Format(CalcDate(Formula, 20240131D), 0, 9));
    end;

    [Test]
    procedure Evaluate_Accepted()
    begin
        Assert.AreEqual('true [1D] 2024-02-01', Outcome('1d'), '1d');
        Assert.AreEqual('true [1D] 2024-02-01', Outcome('1D'), '1D');
        Assert.AreEqual('true [] 2024-01-31', Outcome('< >'), '< >');
        Assert.AreEqual('true [-1W] 2024-01-24', Outcome('-1W'), '-1W');
        Assert.AreEqual('true [CM] 2024-01-31', Outcome('CM'), 'CM');
        Assert.AreEqual('true [1M+CM] 2024-02-29', Outcome('<1M+CM>'), '<1M+CM>');
        Assert.AreEqual('true [+1D] 2024-02-01', Outcome('+1D'), '+1D');
        Assert.AreEqual('true [D1] 2024-02-01', Outcome('D1'), 'D1');
        Assert.AreEqual('true [1Y-1D] 2025-01-30', Outcome('1Y-1D'), '1Y-1D');
        Assert.AreEqual('true [WD1] 2024-02-05', Outcome('WD1'), 'WD1');
        Assert.AreEqual('true [-WD1] 2024-01-29', Outcome('<-WD1>'), '<-WD1>');
        Assert.AreEqual('true [CQ] 2024-03-31', Outcome('CQ'), 'CQ');
        Assert.AreEqual('true [1D] 2024-02-01', Outcome(' 1D '), ' 1D ');
        Assert.AreEqual('true [1D] 2024-02-01', Outcome('1 D'), '1 D');
    end;

    [Test]
    procedure Evaluate_Refused()
    begin
        Assert.AreEqual('false', Outcome('1X'), '1X');
        Assert.AreEqual('false', Outcome('D'), 'D');
        Assert.AreEqual('false', Outcome('<D>'), '<D>');
        Assert.AreEqual('false', Outcome('1d1w'), '1d1w');
        Assert.AreEqual('false', Outcome('1D1W'), '1D1W');
        Assert.AreEqual('false', Outcome('1'), '1');
        Assert.AreEqual('false', Outcome('LW'), 'LW');
        Assert.AreEqual('false', Outcome('1.5D'), '1.5D');
    end;

    [Test]
    procedure CalcDate_EmptyFormula()
    var
        Formula: DateFormula;
        Result: Date;
    begin
        Evaluate(Formula, '');

        Assert.AreEqual(20240115D, CalcDate(Formula, 20240115D), 'a real date comes back');
        Assert.AreEqual(20240115D, CalcDate('', 20240115D), 'the empty text too');

        asserterror Result := CalcDate(Formula, 0D);
        Assert.IsTrue(GetLastErrorText().StartsWith('You cannot base a date calculation on an undefined date.'), 'empty formula on the undefined date');
    end;
}
