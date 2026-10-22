// @expect AL0619 | The attribute 'Caption' on procedure 'Run1' is not allowed. Add attribute 'ServiceEnabled' to the procedure or move it into an application object of type API.
// The Caption attribute on a procedure of a test codeunit (a plain codeunit accepts it). With ServiceEnabled it compiles: tests/al-language/lt-ac/ACAttributes.al.
codeunit 59060 "MNC CaptionAttr 0980"
{
    Subtype = Test;

    [Caption('A caption')]
    procedure Run1()
    begin
    end;
}
