// @expect AL0282 | The member referenced by event subscriber 'Printer' parameter 'Extra' is not found.
// A subscriber to Reporting Triggers.GetPrinterName declares a parameter the event does not have.
codeunit 50000 "MNC Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPrinterName', '', false, false)]
    local procedure Printer(ReportID: Integer; var PrinterName: Text[250]; Extra: Integer)
    begin
    end;
}
