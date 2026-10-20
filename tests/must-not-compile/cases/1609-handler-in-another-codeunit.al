// @expect AL0499 | The handler function OtherMsgHandler was not found. Make sure the procedure is defined and has a handler attribute.
// Corpus issue #667 item 19: [HandlerFunctions] names a [MessageHandler] that another test codeunit declares; handlers must be in the same codeunit.
codeunit 59610 "MNC Hnd Other 1609"
{
    Subtype = Test;

    [MessageHandler]
    procedure OtherMsgHandler(Msg: Text[1024])
    begin
    end;
}
codeunit 59611 "MNC Hnd Tests 1609"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('OtherMsgHandler')]
    procedure T()
    begin
        Message('x');
    end;
}
