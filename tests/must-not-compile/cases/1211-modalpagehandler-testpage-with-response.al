// @expect AL0241 | The signature of procedure 'Handler' does not match the signature required by attribute 'ModalPageHandler'. The expected signature is: Handler(var Page: TestPage).
// A [ModalPageHandler] with a TestPage parameter takes no Response parameter (corpus issue 652 item 7, writer AZ): only the Page form has
// var Response: Action.
page 51212 "MNC AZ Modal TestPage"
{
    PageType = Card;
    SourceTable = Integer;
}

codeunit 51213 "MNC AZ TestPage Handler"
{
    Subtype = Test;

    [ModalPageHandler]
    procedure Handler(var P: TestPage "MNC AZ Modal TestPage"; var Response: Action)
    begin
    end;
}
