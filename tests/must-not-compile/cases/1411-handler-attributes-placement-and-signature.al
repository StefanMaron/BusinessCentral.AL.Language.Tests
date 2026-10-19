// @expect AL0243 | Attribute ConfirmHandler can only be used within a codeunit of subtype Test.
// @expect AL0243 | Attribute MessageHandler can only be used within a codeunit of subtype Test.
// @expect AL0245 | The signature of procedure 'LocalConfirm' does not match the signature required by attribute 'ConfirmHandler': procedure cannot be local.
// @expect AL0240 | The signature of procedure 'NoVarReply' does not match the signature required by attribute 'ConfirmHandler': parameter 2 is expected to be of type 'var Boolean' but found type 'Boolean'.
// @expect AL0240 | The signature of procedure 'IntMessage' does not match the signature required by attribute 'MessageHandler': parameter 1 is expected to be of type 'Text[1024]' but found type 'Integer'.
// @expect AL0240 | The signature of procedure 'ShortMessage' does not match the signature required by attribute 'MessageHandler': parameter 1 is expected to be of type 'Text[1024]' but found type 'Text[10]'.
// Handler attributes: ConfirmHandler and MessageHandler outside a test codeunit (AL0243, the ReportHandler form is case 0986); a local
// handler (AL0245); a Confirm reply that is not var, an Integer message and a Text[10] message (AL0240). A Text or Text[1024] parameter
// both compile (Text at run time: handlers/TestUnhandledUiAndDialogDefaults.al). Corpus issue 664 item 84. Writer BO. (6 diagnostics)
codeunit 51411 "MNC BO 1411 Normal"
{
    [ConfirmHandler]
    procedure Confirm1(Question: Text[1024]; var Reply: Boolean) begin end;
    [MessageHandler]
    procedure Message1(Msg: Text[1024]) begin end;
}

codeunit 51412 "MNC BO 1411 Test"
{
    Subtype = Test;

    [ConfirmHandler]
    local procedure LocalConfirm(Question: Text[1024]; var Reply: Boolean) begin end;
    [ConfirmHandler]
    procedure NoVarReply(Question: Text[1024]; Reply: Boolean) begin end;
    [MessageHandler]
    procedure IntMessage(Msg: Integer) begin end;
    [MessageHandler]
    procedure ShortMessage(Msg: Text[10]) begin end;
    [ConfirmHandler]
    procedure TextConfirm(Question: Text; var Reply: Boolean) begin end;
    [MessageHandler]
    procedure TextMessage(Msg: Text) begin end;
}
