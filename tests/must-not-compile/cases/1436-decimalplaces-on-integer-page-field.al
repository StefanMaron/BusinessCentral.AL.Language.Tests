// @expect AL0843 | The property 'DecimalPlaces' can only be used if the field's type is 'Decimal'.
// @expect AL0843 | The property 'DecimalPlaces' can only be used if the field's type is 'Decimal'.
// DecimalPlaces = 0 : 5 on a page field whose source is an Integer variable and on one whose source is the literal 0 (microsoft/AL
// issue 392): both are refused. The same property on a field whose source is the literal 0.0 compiles (no third diagnostic).
page 51436 "MNC BP P1436"
{
    PageType = Card;

    layout
    {
        area(Content)
        {
            field(IntVar; IntVar) { DecimalPlaces = 0 : 5; }
            field(Lit; 0) { DecimalPlaces = 0 : 5; }
            field(LitDecimal; 0.0) { DecimalPlaces = 0 : 5; }
        }
    }

    var
        IntVar: Integer;
}
