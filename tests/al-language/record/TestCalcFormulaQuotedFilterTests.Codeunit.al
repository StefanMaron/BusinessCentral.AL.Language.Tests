// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFQ Entry Type (60302), CFQ Header (60303), CFQ Line (60304),
//                CFQ Log (60305), CFQ Negated View Report (60306), CFQ Paren View Report (60307)
//
// CLAIM: a CalcFormula `filter(...)` condition, and a report data item's
// `DataItemTableView ... where(... = filter(...))`, both accept an AL quoted
// identifier as the filter value and aggregate/iterate the rows carrying that
// enum member.
//
// AL quotes an identifier with double quotes; BC's filter grammar quotes a literal
// with single quotes and treats a double quote as an ordinary character. So the two
// spellings have to be reconciled somewhere between the AL source and the filter
// engine, and whether they are is a fact about BC, not about any one consumer.
//
// The member names here are the ones that make the difference observable: a name with
// a space (unquoted, the space would be discarded), and a name with parentheses
// (unquoted, they would become grouping). Base Application writes both shapes --
// "Detailed CV Ledger Entry Type" has Payment Discount (VAT Excl.), and Report 321
// "Vendor - Balance to Date" writes where("Entry Type" = filter(<> "Initial Entry")).
codeunit 60308 "CFQ Quoted Filter Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        HeaderRec: Record "CFQ Header";
        LineRec: Record "CFQ Line";
        LogRec: Record "CFQ Log";
    begin
        HeaderRec.DeleteAll(false);
        LineRec.DeleteAll(false);
        LogRec.DeleteAll(false);
        Cleanup.Initialize();
    end;

    local procedure Seed()
    var
        HeaderRec: Record "CFQ Header";
    begin
        HeaderRec.Init();
        HeaderRec."No." := 'H1';
        HeaderRec.Insert(false);

        AddLine(1, 'H1', "CFQ Entry Type"::"Initial Entry", 100);
        AddLine(2, 'H1', "CFQ Entry Type"::"Payment Discount (VAT Excl.)", 25);
        AddLine(3, 'H1', "CFQ Entry Type"::Application, 7);
        AddLine(4, 'H1', "CFQ Entry Type"::" ", 3);
    end;

    local procedure AddLine(EntryNo: Integer; HeaderNo: Code[20]; EntryType: Enum "CFQ Entry Type"; LineAmount: Decimal)
    var
        LineRec: Record "CFQ Line";
    begin
        LineRec.Init();
        LineRec."Entry No." := EntryNo;
        LineRec."Header No." := HeaderNo;
        LineRec."Entry Type" := EntryType;
        LineRec.Amount := LineAmount;
        LineRec.Insert(false);
    end;

    local procedure LogMarkerCount(WantedMarker: Text): Integer
    var
        LogRec: Record "CFQ Log";
    begin
        LogRec.SetRange(Marker, WantedMarker);
        exit(LogRec.Count());
    end;

    [Test]
    procedure CalcFormula_FilterOnQuotedNameWithSpace_AggregatesThatMemberOnly()
    var
        HeaderRec: Record "CFQ Header";
    begin
        // [SCENARIO] filter("Initial Entry") -- a member name whose only unusual
        //            property is the space in it.
        Initialize();
        Seed();

        HeaderRec.Get('H1');
        HeaderRec.CalcFields("Initial Amount");

        Assert.AreEqual(100, HeaderRec."Initial Amount",
            'filter("Initial Entry") must sum only the Initial Entry line');
    end;

    [Test]
    procedure CalcFormula_FilterOnQuotedNameWithParentheses_AggregatesThatMemberOnly()
    var
        HeaderRec: Record "CFQ Header";
    begin
        // [SCENARIO] filter("Payment Discount (VAT Excl.)") -- parentheses inside the
        //            member name must stay literal, not become grouping.
        Initialize();
        Seed();

        HeaderRec.Get('H1');
        HeaderRec.CalcFields("Discount Amount");

        Assert.AreEqual(25, HeaderRec."Discount Amount",
            'filter("Payment Discount (VAT Excl.)") must sum only the discount line');
    end;

    [Test]
    procedure CalcFormula_FilterAlternationOfQuotedAndUnquotedNames_AggregatesBoth()
    var
        HeaderRec: Record "CFQ Header";
    begin
        // [SCENARIO] filter(Application | "Initial Entry") -- the alternation operator
        //            still separates the two names, and only the quoted one is a literal.
        Initialize();
        Seed();

        HeaderRec.Get('H1');
        HeaderRec.CalcFields("Alternation Amount");

        Assert.AreEqual(107, HeaderRec."Alternation Amount",
            'filter(Application | "Initial Entry") must sum both named members and nothing else');
    end;

    [Test]
    procedure CalcFormula_NegatedFilterOnQuotedBlankMember_ExcludesOnlyThatMember()
    var
        HeaderRec: Record "CFQ Header";
    begin
        // [SCENARIO] filter(<> " ") -- unquoted, the space would be discarded as
        //            whitespace and <> would be left with no operand.
        Initialize();
        Seed();

        HeaderRec.Get('H1');
        HeaderRec.CalcFields("Non Blank Amount");

        Assert.AreEqual(132, HeaderRec."Non Blank Amount",
            'filter(<> " ") must sum every line except the blank-member one');
    end;

    [Test]
    procedure CalcFormula_FilterOnQuotedBlankMember_CountsOnlyThatMember()
    var
        HeaderRec: Record "CFQ Header";
    begin
        // [SCENARIO] The un-negated half of the previous claim, so a formula that
        //            matched everything could not pass both.
        Initialize();
        Seed();

        HeaderRec.Get('H1');
        HeaderRec.CalcFields("Blank Count");

        Assert.AreEqual(1, HeaderRec."Blank Count",
            'filter(" ") must count exactly the one blank-member line');
    end;

    [Test]
    procedure CalcFormula_FilterOnMemberWithNoRows_AggregatesToZero()
    var
        HeaderRec: Record "CFQ Header";
    begin
        // [SCENARIO] The negative direction: with the matching line removed, the same
        //            formula must fall to zero rather than quietly summing everything.
        Initialize();
        Seed();

        RemoveLine(2);

        HeaderRec.Get('H1');
        HeaderRec.CalcFields("Discount Amount");

        Assert.AreEqual(0, HeaderRec."Discount Amount",
            'with no discount line present, filter("Payment Discount (VAT Excl.)") must sum to 0');
    end;

    local procedure RemoveLine(EntryNo: Integer)
    var
        LineRec: Record "CFQ Line";
    begin
        LineRec.Get(EntryNo);
        LineRec.Delete(false);
    end;

    [Test]
    procedure DataItemTableView_NegatedQuotedFilter_IteratesEveryOtherMember()
    begin
        // [SCENARIO] Report 321's shape: where("Entry Type" = filter(<> "Initial Entry")).
        Initialize();
        Seed();

        Report.Run(Report::"CFQ Negated View Report", false, false);

        Assert.AreEqual(3, LogMarkerCount('negated'),
            'the data item must visit the three lines that are not Initial Entry');
    end;

    [Test]
    procedure DataItemTableView_QuotedFilterWithParentheses_IteratesThatMemberOnly()
    begin
        // [SCENARIO] The same grammar, positively: parentheses inside the member name
        //            must not end the filter() call early or become grouping.
        Initialize();
        Seed();

        Report.Run(Report::"CFQ Paren View Report", false, false);

        Assert.AreEqual(1, LogMarkerCount('paren'),
            'the data item must visit exactly the one Payment Discount (VAT Excl.) line');
    end;
}
