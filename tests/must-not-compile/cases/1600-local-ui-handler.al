// @expect AL0245 | The signature of procedure 'LocalModal' does not match the signature required by attribute 'ModalPageHandler': procedure cannot be local.
// @expect AL0245 | The signature of procedure 'LocalMessage' does not match the signature required by attribute 'MessageHandler': procedure cannot be local.
// A UI handler procedure must not be local: the compiler refuses it (corpus issue 667, item 13; the lead from microsoft/AL issue 2667
// said a local handler compiled and the test then failed with an unhandled UI error).
codeunit 50620 "MNC CA 1600"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('LocalModal,LocalMessage')]
    procedure Probe()
    begin
        Page.RunModal(Page::"Customer List");
        Message('x');
    end;

    [ModalPageHandler]
    local procedure LocalModal(var P: TestPage "Customer List")
    begin
    end;

    [MessageHandler]
    local procedure LocalMessage(Msg: Text[1024])
    begin
    end;
}
