// @expect AL0518 | A method with name 'PickHandler' possessing one Handler attribute is already defined in this test codeunit.
// @expect AL0518 | A method with name 'PickHandler' possessing one Handler attribute is already defined in this test codeunit.
// Corpus issue #667 item 18: a [ModalPageHandler] and a [MessageHandler] with the same name (an overload) in one test codeunit.
// A handler and a plain procedure of the same name with other parameters compile (see tests/al-language/misc/lt-cb-odd-leads/CbHandlerNames.al).
page 59608 "MNC Hnd Card 1608"
{
    PageType = Card;
    layout { area(Content) { } }
}
codeunit 59609 "MNC Hnd Tests 1608"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('PickHandler')]
    procedure T()
    begin
        Page.RunModal(Page::"MNC Hnd Card 1608");
        Message('x');
    end;

    [ModalPageHandler]
    procedure PickHandler(var Pg: TestPage "MNC Hnd Card 1608")
    begin
        Pg.OK().Invoke();
    end;

    [MessageHandler]
    procedure PickHandler(Msg: Text[1024])
    begin
    end;
}
