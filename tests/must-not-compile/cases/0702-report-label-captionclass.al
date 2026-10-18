// @expect AL0439 | The label's property is not valid. Possible properties are: Comment, Locked, MaxLength.
// A report label takes Comment, Locked and MaxLength only; CaptionClass is not one of them.
report 59702 "MNC U Rep 702"
{
    ProcessingOnly = true;
    labels { Lbl = 'x', CaptionClass = '3,Foo'; }
}
