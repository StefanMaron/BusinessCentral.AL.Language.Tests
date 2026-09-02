// Support enum for TestCalcFormulaQuotedFilterTests.Codeunit.al.
//
// Member names deliberately chosen to need AL's double-quote identifier form:
// one containing a space, one containing parentheses (the shape Base Application's
// "Detailed CV Ledger Entry Type" uses for Payment Discount (VAT Excl.)), and the
// blank member AL spells with a single space.
enum 60302 "CFQ Entry Type"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Initial Entry")
    {
        Caption = 'Initial Entry';
    }
    value(2; "Payment Discount (VAT Excl.)")
    {
        Caption = 'Payment Discount (VAT Excl.)';
    }
    value(3; Application)
    {
        Caption = 'Application';
    }
}
