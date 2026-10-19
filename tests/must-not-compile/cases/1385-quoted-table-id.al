// @expect AL0806 | The object ID '18' should not be surrounded with quotes.
// Corpus #664 item 31. Record "18" is not the table named 18 and not table 18: AL0806. Record 18 (no quotes) compiles and is Customer.
codeunit 51385 "MNC BM C1385"
{
    procedure P(): Integer
    var
        Cust: Record "18";
        Cust2: Record 18;
    begin
        exit(Cust2.Count());
    end;
}
