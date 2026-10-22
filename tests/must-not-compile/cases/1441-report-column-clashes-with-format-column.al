// @expect AL0397 | The name 'AmountFormat' clashes with 'Amount' column's format column name.
// Report column names that end in "format" (microsoft/AL issue 1548): a Decimal column Amount gets a hidden format column AmountFormat,
// so a second column with that name is refused. Names that end in "format" but match no Decimal column compile: CurrAmount_Autoformat,
// FormatX, myFORMAT (no diagnostic for them).
table 51441 "MNC BP T1441"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
report 51441 "MNC BP R1441"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "MNC BP T1441")
        {
            column(Amount; Amount) { }
            column(AmountFormat; Id) { }
            column(CurrAmount_Autoformat; Amount) { }
            column(FormatX; Id) { }
            column(myFORMAT; Id) { }
        }
    }
}
