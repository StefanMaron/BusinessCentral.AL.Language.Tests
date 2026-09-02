// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFS Line (60910), CFS Header (60911)
//
// Migrated from AL Runner tests/runner-extras/calcformula-sign-and-filters (CfsTests.Codeunit.al).
// These assert plain FlowField semantics -- a leading '-' negating the aggregate, const and
// filter where-conditions excluding rows, and multiple conditions ANDing so an impossible
// combination sums to zero -- so they belong here rather than in the runner's own suite.

// Issues #1708 (a signed FlowField formula) and #1709 (const()/filter() where-conditions).
//
// Before the fix both failed SILENTLY: `-sum(...)` was refused by the CalcFormula parser, so
// the FlowField's CalculationFormula stayed EmptyFormula and CalcFields() left the field at 0;
// const()/filter() conditions were dropped, so the FlowField aggregated rows AL had excluded
// and returned a plausible wrong number. Nothing threw in either case.
//
// The seed rows are chosen so that every FlowField lands on a DIFFERENT value. An
// implementation that ignores the sign, ignores the conditions, or returns the type default
// fails at least one assertion in every test below.
codeunit 60912 "CFS Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    local procedure Seed(): Code[20]
    var
        CfsLine: Record "CFS Line";
        CfsHeader: Record "CFS Header";
    begin
        CfsLine.DeleteAll();
        CfsHeader.DeleteAll();

        CfsHeader.Init();
        CfsHeader."No." := 'D1';
        CfsHeader.Insert(false);

        // Entry 1: Open, Status Open,     100
        // Entry 2: not Open, Status Released, 20
        // Entry 3: Open, Status Closed,     3
        AddLine(1, 'D1', 100, true, CfsLine.Status::Open);
        AddLine(2, 'D1', 20, false, CfsLine.Status::Released);
        AddLine(3, 'D1', 3, true, CfsLine.Status::Closed);

        // A second document, never asserted on: proves the parent link still filters.
        AddLine(4, 'D2', 999, true, CfsLine.Status::Open);

        // A third document with NO lines at all, so the exist tests below can assert both
        // directions of the same FlowField rather than only the populated one.
        CfsHeader.Init();
        CfsHeader."No." := 'D3';
        CfsHeader.Insert(false);

        exit('D1');
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; Amt: Decimal; IsOpen: Boolean; Sts: Option)
    var
        CfsLine: Record "CFS Line";
    begin
        CfsLine.Init();
        CfsLine."Entry No." := EntryNo;
        CfsLine."Doc No." := DocNo;
        CfsLine.Amount := Amt;
        CfsLine.Open := IsOpen;
        CfsLine.Status := Sts;
        CfsLine.Insert(false);
    end;

    [Test]
    procedure SignedFormulaNegatesTheAggregate()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] Three lines on D1 totalling 123, plus 999 on another document.
        CfsHeader.Get(Seed());

        // [WHEN] Both the plain and the signed sum of the same rows are calculated.
        CfsHeader.CalcFields("Total Amount", "Negated Total");

        // [THEN] The unsigned formula is unchanged...
        Assert.AreEqual(123, CfsHeader."Total Amount",
            'the unsigned sum must aggregate only this document''s lines');

        // [THEN] ...and the signed one is its negation. 0 is the pre-fix value (the formula
        // was refused outright), 123 is the value a dropped sign would give.
        Assert.AreEqual(-123, CfsHeader."Negated Total",
            '-sum(...) must negate the aggregate, not drop the sign and not stay at 0');
    end;

    [Test]
    procedure ConstConditionExcludesRows()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] Two of the three D1 lines are Open (100 and 3); one is not (20).
        CfsHeader.Get(Seed());

        // [WHEN]
        CfsHeader.CalcFields("Total Amount", "Open Total", "Closed Count");

        // [THEN] const(true) keeps only the Open rows — a dropped condition would give 123.
        Assert.AreEqual(103, CfsHeader."Open Total",
            'Open = const(true) must exclude the non-Open line');
        Assert.AreNotEqual(CfsHeader."Total Amount", CfsHeader."Open Total",
            'the const condition must actually change which rows are summed');

        // [THEN] const(false) selects the complement, through a count formula.
        Assert.AreEqual(1, CfsHeader."Closed Count",
            'Open = const(false) must count exactly the one non-Open line');
    end;

    [Test]
    procedure FilterConditionAppliesAlternationAndRange()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] Statuses Open / Released / Closed on entries 1 / 2 / 3.
        CfsHeader.Get(Seed());

        // [WHEN]
        CfsHeader.CalcFields("Active Total", "Range Total");

        // [THEN] filter(Open|Released) is one expression selecting two option members.
        Assert.AreEqual(120, CfsHeader."Active Total",
            'Status = filter(Open|Released) must sum the Open and Released lines only');

        // [THEN] filter(2..3) is a range over the entry numbers.
        Assert.AreEqual(23, CfsHeader."Range Total",
            '"Entry No." = filter(2..3) must sum entries 2 and 3 only');
    end;

    [Test]
    procedure ConditionsAreAndedSoAnImpossibleCombinationSumsToZero()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] The only Closed line (entry 3) IS Open, so no line is both Closed and
        // not Open.
        CfsHeader.Get(Seed());

        // [WHEN]
        CfsHeader.CalcFields("Unmatched Total", "Negated Released Total");

        // [THEN] Both conditions apply, and they narrow together — dropping either one
        // would yield 3 or 20 rather than nothing.
        Assert.AreEqual(0, CfsHeader."Unmatched Total",
            'Status = const(Closed) AND Open = const(false) must select no line at all');

        // [THEN] Sign and const condition compose: only the Released line, negated.
        Assert.AreEqual(-20, CfsHeader."Negated Released Total",
            '-sum(... Status = const(Released)) must negate the filtered subtotal');
    end;

    [Test]
    procedure ExistFormulaAnswersWhetherAnyRowMatches()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] D1 has three lines; D3 has none.
        CfsHeader.Get(Seed());

        // [WHEN]
        CfsHeader.CalcFields("Has Lines", "Has Line In Entry Range");

        // [THEN] The unsigned exist is true for a document that has matching lines.
        Assert.IsTrue(CfsHeader."Has Lines",
            'exist(...) must be true for a document that has lines');
        Assert.IsTrue(CfsHeader."Has Line In Entry Range",
            'exist(... "Entry No." = filter(2..3)) must be true — entries 2 and 3 are on D1');

        // [THEN] And false for one that has none.
        CfsHeader.Get('D3');
        CfsHeader.CalcFields("Has Lines", "Has Line In Entry Range");
        Assert.IsFalse(CfsHeader."Has Lines",
            'exist(...) must be false for a document with no lines');
        Assert.IsFalse(CfsHeader."Has Line In Entry Range",
            'exist(...) with a range condition must be false for a document with no lines');
    end;

    [Test]
    procedure SignedExistFormulaNegatesTheBoolean()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] D1 has three lines; D3 has none.
        CfsHeader.Get(Seed());

        // [WHEN] The signed and unsigned form of the same exist are calculated together.
        CfsHeader.CalcFields("Has Lines", "Has No Lines",
                             "Has Line In Entry Range", "Has No Line In Entry Range");

        // [THEN] -exist(...) is the logical NOT of exist(...), never a copy of it. A
        // dropped sign gives true here, which is the whole point of asserting both.
        Assert.IsFalse(CfsHeader."Has No Lines",
            '-exist(...) must be false for a document that HAS lines');
        Assert.AreNotEqual(CfsHeader."Has Lines", CfsHeader."Has No Lines",
            '-exist(...) and exist(...) over the same rows must disagree');

        // [THEN] The same holds when the first field in the where clause is an Integer
        // rather than a Code — a distinction AL does not expose and must not change.
        Assert.IsFalse(CfsHeader."Has No Line In Entry Range",
            '-exist(... "Entry No." = filter(2..3)) must be false — entries 2 and 3 exist on D1');
        Assert.AreNotEqual(CfsHeader."Has Line In Entry Range", CfsHeader."Has No Line In Entry Range",
            'the signed and unsigned exist must disagree whatever the where-clause field type');

        // [THEN] The other direction: on a document with no lines, the negated form is true.
        CfsHeader.Get('D3');
        CfsHeader.CalcFields("Has No Lines", "Has No Line In Entry Range");
        Assert.IsTrue(CfsHeader."Has No Lines",
            '-exist(...) must be true for a document with no lines');
        Assert.IsTrue(CfsHeader."Has No Line In Entry Range",
            '-exist(...) with a range condition must be true for a document with no lines');
    end;

    [Test]
    procedure SignedExistComposesWithAndedConditions()
    var
        CfsHeader: Record "CFS Header";
    begin
        // [GIVEN] The only Closed line (entry 3) IS Open, so no line is both Closed and
        // not Open — the same impossible combination the sum test uses.
        CfsHeader.Get(Seed());

        // [WHEN]
        CfsHeader.CalcFields("Has Lines", "Has No Closed Not Open Line");

        // [THEN] No row matches, so the negated exist is true — and it takes both the
        // ANDed conditions and the sign to get there. Dropping either gives false.
        Assert.IsTrue(CfsHeader."Has No Closed Not Open Line",
            '-exist(... Status = const(Closed), Open = const(false)) must be true: no line matches');
        Assert.IsTrue(CfsHeader."Has Lines",
            'the same document still has lines, so the conditions are what excluded them');
    end;
}
