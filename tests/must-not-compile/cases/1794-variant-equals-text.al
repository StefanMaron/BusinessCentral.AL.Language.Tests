// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Variant' and 'Text'
// Corpus issue 670 (AL issue 812): a Variant that holds FieldRef.Value, compared with a text using '=', does not compile.
codeunit 51794 "MNC CY C1794"
{
    procedure IsTwo(var FldRef: FieldRef; Txt: Text): Boolean
    var
        V: Variant;
    begin
        V := FldRef.Value;
        exit(V = Txt);
    end;
}
