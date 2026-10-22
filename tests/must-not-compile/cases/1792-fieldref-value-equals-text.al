// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Joker' and 'Text'
// Corpus issue 670 (AL issue 812): FieldRef.Value compared with a text using '=' does not compile. Compare Format(FieldRef.Value) instead.
table 51792 "MNC CY T1792"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = Zero,One,Two; }
    }
}

codeunit 51792 "MNC CY C1792"
{
    procedure IsTwo(var FldRef: FieldRef; Txt: Text): Boolean
    begin
        exit(FldRef.Value = Txt);
    end;
}
