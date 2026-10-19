// @expect AL0240 | The signature of procedure 'Handler' does not match the signature required by attribute 'ModalPageHandler': parameter 1 is expected to be of type 'var TestPage' but found type 'var Page "MNC AZ Modal Page"'. The expected signature is: Handler(var Page: TestPage).
// A [ModalPageHandler] whose first parameter is a Page (not a TestPage) must also declare var Response: Action (corpus issue 652 item 7,
// writer AZ). The Page form with Response compiles (pinned at run time in errors/lt-ms-refusals-129/P129Handlers.al).
page 51210 "MNC AZ Modal Page"
{
    PageType = Card;
    SourceTable = Integer;
}

codeunit 51211 "MNC AZ Page Handler"
{
    Subtype = Test;

    [ModalPageHandler]
    procedure Handler(var P: Page "MNC AZ Modal Page")
    begin
    end;
}
