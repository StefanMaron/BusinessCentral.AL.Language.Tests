// @expect AL0103 | Constant value '100000000000000' is outside the range for an Integer
// A for loop over an Integer control variable with an end bound literal beyond the Integer range does not compile (corpus issue 672,
// item 36; Learn's control statements page says it is a runtime error). A BigInteger variable as the end bound compiles: see
// tests/al-language/misc/lt-cq-odd-leads/CqOddLeads.al Item36.
codeunit 51732 "MNC CQ C1732"
{
    procedure Loop()
    var
        Count: Integer;
        Steps: Integer;
    begin
        for Count := 1000 to 100000000000000 do
            Steps += 1;
    end;
}
