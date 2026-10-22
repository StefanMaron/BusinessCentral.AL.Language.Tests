// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Joker' and 'Integer'
// Corpus issue 670 (AL issue 812): FieldRef.Value compared with an integer (an option ordinal) using '=' does not compile either.
codeunit 51793 "MNC CY C1793"
{
    procedure IsTwo(var FldRef: FieldRef): Boolean
    begin
        exit(FldRef.Value = 2);
    end;
}
