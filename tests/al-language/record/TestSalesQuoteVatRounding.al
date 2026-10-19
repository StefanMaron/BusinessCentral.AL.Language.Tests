// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-round-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none -- every table is Base Application's own (Sales Header 36, Sales Line 37,
//   Item 27, General Ledger Setup 98) and the aggregate under test is Base Application's
//   "Customer Mgt." (50) CalcAmountsOnQuotes, the function behind the Customer Statistics tile.
// BC versions: 27.0+
//
// CLAIM UNDER TEST: the amount Base Application reports for a customer's open sales quotes is
// NOT the sum of the quotes' net amounts. "Customer Mgt." adds up "Outstanding Amount (LCY)" --
// which INCLUDES VAT, rounded per line -- grouped by VAT %, backs the VAT out again with
// `Sum * 100 / (100 + VAT %)` and rounds once. For two lines of 7.67 and 6.67 at 10% VAT the
// round trip lands on 14.35 while 7.67 + 6.67 = 14.34, a cent apart.
//
// WHY IT IS HERE: Microsoft's own test `AmountOnQuotes` (Tests-SMB, codeunit 138009) draws its
// line prices from `LibraryRandom.RandDec(10, 2)` and compares that plain sum to the aggregate, so
// it fails for exactly these two values under one random seed and passes under another
// (AlRunner issue https://github.com/StefanMaron/BusinessCentral.AL.Runner/issues/4867). The
// question was whether the cent comes from AL Runner's arithmetic or from BC. These tests give
// the values as literals, with no randomness, so a service tier can answer it.
//
// 7.67 * 1.10 = 8.437 -> 8.44, 6.67 * 1.10 = 7.337 -> 7.34, (8.44 + 7.34) * 100 / 110 =
// 14.3454... -> 14.35. None of the three is a rounding tie.
codeunit 69930 "Test Quote Vat Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CustNoTok: Label 'ALQVR-CUST', Locked = true;
        ItemNoTok: Label 'ALQVR-ITEM', Locked = true;
        VatBusTok: Label 'ALQVRB', Locked = true;
        VatProdTok: Label 'ALQVRP', Locked = true;

    /// The arithmetic on its own, on literals, with nothing from Base Application in the way.
    [Test]
    procedure Decimal_QuoteRoundTrip_At10PercentVat_IsACentAboveThePlainSum()
    var
        PlainSum: Decimal;
        Line1InclVat: Decimal;
        Line2InclVat: Decimal;
        BackedOut: Decimal;
    begin
        PlainSum := 7.67 + 6.67;
        Line1InclVat := Round(7.67 * (100 + 10) / 100, 0.01);
        Line2InclVat := Round(6.67 * (100 + 10) / 100, 0.01);
        BackedOut := Round((Line1InclVat + Line2InclVat) * 100 / (100 + 10), 0.01);

        Assert.AreEqual(14.34, PlainSum, 'the plain sum');
        Assert.AreEqual(8.44, Line1InclVat, '7.67 plus 10 percent, rounded');
        Assert.AreEqual(7.34, Line2InclVat, '6.67 plus 10 percent, rounded');
        Assert.AreEqual(14.35, BackedOut, 'the VAT backed out of the two rounded gross amounts');
    end;

    /// Base Application's aggregate over lines whose gross amounts are given, not computed.
    [Test]
    procedure CustomerMgt_CalcAmountsOnQuotes_BacksVatOutOfTheSummedGrossAmount()
    var
        CustomerMgt: Codeunit "Customer Mgt.";
        QuoteCount: Integer;
        QuoteAmount: Decimal;
    begin
        Initialize();
        InsertQuote('ALQVR-Q1', 8.44);
        InsertQuote('ALQVR-Q2', 7.34);

        QuoteAmount := CustomerMgt.CalcAmountsOnQuotes(CustNoTok, QuoteCount);

        Assert.AreEqual(2, QuoteCount, 'quote count');
        Assert.AreEqual(14.35, QuoteAmount, 'quote amount: (8.44 + 7.34) * 100 / 110, rounded');
    end;

    /// What the Microsoft test does: set a unit price, validate it, let the Sales Line work out its amounts.
    [Test]
    procedure SalesLine_ValidateUnitPrice_At10PercentVat_RoundsTheGrossAmountPerLine()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        InsertQuoteHeader('ALQVR-Q1');

        InsertPricedLine(SalesLine, 'ALQVR-Q1', 7.67);

        Assert.AreEqual(7.67, SalesLine.Amount, 'Amount');
        Assert.AreEqual(8.44, SalesLine."Amount Including VAT", 'Amount Including VAT');
        Assert.AreEqual(8.44, SalesLine."Outstanding Amount (LCY)", 'Outstanding Amount (LCY)');
    end;

    /// The two together: the sequence AmountOnQuotes runs, for the two values that expose the cent.
    [Test]
    procedure CustomerMgt_CalcAmountsOnQuotes_TwoLinesPricedBelow10_IsNotThePlainSum()
    var
        SalesLine: Record "Sales Line";
        CustomerMgt: Codeunit "Customer Mgt.";
        QuoteCount: Integer;
        QuoteAmount: Decimal;
    begin
        Initialize();
        InsertQuoteHeader('ALQVR-Q1');
        InsertPricedLine(SalesLine, 'ALQVR-Q1', 7.67);
        InsertQuoteHeader('ALQVR-Q2');
        InsertPricedLine(SalesLine, 'ALQVR-Q2', 6.67);

        QuoteAmount := CustomerMgt.CalcAmountsOnQuotes(CustNoTok, QuoteCount);

        Assert.AreEqual(2, QuoteCount, 'quote count');
        Assert.AreEqual(14.35, QuoteAmount, 'quote amount for unit prices 7.67 and 6.67');
        Assert.AreNotEqual(7.67 + 6.67, QuoteAmount, 'the aggregate is not the plain sum of the unit prices');
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        GLSetup: Record "General Ledger Setup";
    begin
        SalesLine.SetRange("Bill-to Customer No.", CustNoTok);
        SalesLine.DeleteAll();
        SalesHeader.SetRange("Bill-to Customer No.", CustNoTok);
        SalesHeader.DeleteAll();
        if Item.Get(ItemNoTok) then
            Item.Delete();
        Item.Init();
        Item."No." := ItemNoTok;
        Item.Insert(false);

        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert(false);
        end;
        Assert.AreEqual(0.01, GLSetup."Amount Rounding Precision", 'precondition: Amount Rounding Precision');
    end;

    local procedure InsertQuoteHeader(DocNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader."No." := DocNo;
        SalesHeader."Sell-to Customer No." := CustNoTok;
        SalesHeader."Bill-to Customer No." := CustNoTok;
        SalesHeader."Prices Including VAT" := false;
        SalesHeader.Insert(false);
    end;

    /// A quote whose only line carries the given gross amount and 10% VAT, nothing computed.
    local procedure InsertQuote(DocNo: Code[20]; GrossAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        InsertQuoteHeader(DocNo);
        InitLine(SalesLine, DocNo);
        SalesLine."Outstanding Amount (LCY)" := GrossAmount;
        SalesLine.Insert(false);
    end;

    local procedure InsertPricedLine(var SalesLine: Record "Sales Line"; DocNo: Code[20]; UnitPrice: Decimal)
    begin
        InitLine(SalesLine, DocNo);
        SalesLine.Insert(false);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
    end;

    local procedure InitLine(var SalesLine: Record "Sales Line"; DocNo: Code[20])
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Quote;
        SalesLine."Document No." := DocNo;
        SalesLine."Line No." := 10000;
        SalesLine."Bill-to Customer No." := CustNoTok;
        SalesLine."Sell-to Customer No." := CustNoTok;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNoTok;
        SalesLine."VAT Calculation Type" := SalesLine."VAT Calculation Type"::"Normal VAT";
        SalesLine."VAT Bus. Posting Group" := VatBusTok;
        SalesLine."VAT Prod. Posting Group" := VatProdTok;
        SalesLine."VAT Identifier" := 'ALQVR10';
        SalesLine."VAT %" := 10;
    end;
}
