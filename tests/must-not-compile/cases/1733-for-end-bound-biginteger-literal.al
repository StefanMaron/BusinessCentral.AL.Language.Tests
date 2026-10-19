// @expect AL0369 | Constant value '100000000000000' cannot be converted to a 'Integer'.
// The same loop with a BigInteger literal (L suffix) as end bound does not compile either (corpus issue 672, item 36).
codeunit 51733 "MNC CQ C1733"
{
    procedure Loop()
    var
        Count: Integer;
        Steps: Integer;
    begin
        for Count := 1000 to 100000000000000L do
            Steps += 1;
    end;
}
