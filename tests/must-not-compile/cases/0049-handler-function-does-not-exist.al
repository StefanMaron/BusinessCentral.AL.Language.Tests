// @expect AL0499 | The handler function NoSuchHandler was not found. Make sure the procedure is defined and has a handler attribute.
// HandlerFunctions names a procedure that does not exist.
codeunit 50000 "MNC Test"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('NoSuchHandler')]
    procedure T()
    begin
    end;
}
