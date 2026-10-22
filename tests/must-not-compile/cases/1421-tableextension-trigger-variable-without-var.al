// @expect AL0163 | Wrong signature. Correct signature for 'OnBeforeValidate' is 'trigger OnBeforeValidate()'
// A modify() trigger in a table extension declares a local variable without the var keyword. Corpus issue 664 item 102
// (microsoft/AL#5928: it used to publish and fail at run time). Writer BO.
tableextension 51428 "MNC BO 1421" extends Customer
{
    fields
    {
        modify(Name)
        {
            trigger OnBeforeValidate()
            MyVar: Integer;
            begin
                MyVar := 1;
            end;
        }
    }
}
