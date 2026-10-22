// @expect AL0243 | Attribute ReportHandler can only be used within a codeunit of subtype Test.
// The ReportHandler attribute in a codeunit that is not a test codeunit.
report 59090 "MNC RepHandler Rep 0986"
{
    ProcessingOnly = true;
}

codeunit 59091 "MNC ReportHandlerNT 0986"
{
    [ReportHandler]
    procedure Handler(var Rep: Report "MNC RepHandler Rep 0986")
    begin
    end;
}
