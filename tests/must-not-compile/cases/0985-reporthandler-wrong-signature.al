// @expect AL0241 | The signature of procedure 'Handler' does not match the signature required by attribute 'ReportHandler'. The expected signature is: Handler(var Report: Report).
// A ReportHandler procedure without the Report parameter. Runtime test: tests/al-language/lt-ac/ACAttributes.al.
codeunit 59085 "MNC ReportHandlerSig 0985"
{
    Subtype = Test;

    [ReportHandler]
    procedure Handler()
    begin
    end;
}
