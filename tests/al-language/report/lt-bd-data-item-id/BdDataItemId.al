// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own report 81074 and codeunit 81075
// Probe: corpus issue 657. The Data Item ID of Report Data Items is the absolute value of the 32-bit FNV-1a hash of the data item name in UTF-16
// (misc/lt-probes-needed-3/PnC21Metadata.al). The name oBGiBAU hashes to -2147483648, whose absolute value does not fit an Integer.
// BC versions: 27-29

report 81074 "BD Data Item Id"
{
    UsageCategory = None;
    UseRequestPage = false;
    ProcessingOnly = true;

    dataset
    {
        dataitem(oBGiBAU; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
        dataitem(Plain; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

codeunit 81075 "BD Data Item Id Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryItems(var Result: Text)
    var
        Items: Record "Report Data Items";
    begin
        Items.SetRange("Report ID", Report::"BD Data Item Id");
        if Items.FindSet() then
            repeat
                Result += Items.Name + '=' + Format(Items."Data Item ID") + ';';
            until Items.Next() = 0;
    end;

    [Test]
    procedure BdDataItemId_MinValueHash()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        ClearLastError();
        Observer.Observe('ok', Format(TryItems(Result)));
        Observer.Observe('items', Result);
        Observer.ObserveError('read');
        Observer.Finish();
    end;

    [Test]
    procedure BdDataItemId_ReportRuns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('run', Format(Codeunit.Run(Codeunit::"BD Data Item Id Runner")));
        Observer.ObserveError('run');
        Observer.Finish();
    end;
}

codeunit 81077 "BD Data Item Id Runner"
{
    trigger OnRun()
    begin
        Report.Run(Report::"BD Data Item Id", false);
    end;
}
