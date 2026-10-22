// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem app only: the Web Service table (2000000076) has Scope = OnPrem, so a RecordRef from a Target = Cloud app cannot open it.
// Fixtures used: Probe Observer (69160)
// Probe: the columns and the rows of the Web Service table in a fresh tenant (issue 580 item 7). Object id 61281.
// Writer QX (Microsoft's DemoTool): System Application Web Service Management.CreateWebService and CreateTenantWebService on page 42.

codeunit 61281 "LT PT Web Service Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Columns(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + ':' + FR.Name + ':' + Format(FR.Type) + ':' + Format(FR.Length) + ':' + Format(FR.Class) + ';';
        end;
        exit(Result);
    end;

    local procedure Row(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + '=' + Format(FR.Value) + ';';
        end;
        exit(Result);
    end;

    [Test]
    procedure WebService_Content()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Index: Integer;
    begin
        RR.Open(2000000076);
        Observer.Observe('columns', Columns(RR));
        Observer.Observe('count', Format(RR.Count()));
        if RR.FindSet() then
            repeat
                Index += 1;
                Observer.Observe('row' + Format(Index), Row(RR));
            until RR.Next() = 0;
        Observer.Expect('columns', '3:Object Type:Option:4:Normal;9:Service Name:Text:250:Normal;6:Object ID:Integer:4:Normal;12:Published:Boolean:4:Normal;13:ExcludeFieldsOutsideRepeater:Boolean:4:Normal;14:ExcludeNonEditableFlowFields:Boolean:4:Normal;');
        Observer.Expect('count', '17');
        Observer.Expect('row1', '3=Codeunit;9=CompanySetupService;6=1801;12=Yes;13=No;14=No;');
        Observer.Expect('row2', '3=Codeunit;9=ExchangeServiceSetup;6=5324;12=Yes;13=No;14=No;');
        Observer.Expect('row3', '3=Codeunit;9=PageActionProvider;6=2915;12=Yes;13=No;14=No;');
        Observer.Expect('row4', '3=Codeunit;9=SummaryProvider;6=2718;12=Yes;13=No;14=No;');
        Observer.Expect('row5', '3=Page;9=AccountantPortalActivityCues;6=1314;12=Yes;13=No;14=No;');
        Observer.Expect('row6', '3=Page;9=AccountantPortalFinanceCues;6=1315;12=Yes;13=No;14=No;');
        Observer.Expect('row7', '3=Page;9=AccountantPortalUserTasks;6=1316;12=Yes;13=No;14=No;');
        Observer.Expect('row8', '3=Page;9=powerbifinance;6=197;12=Yes;13=No;14=No;');
        Observer.Expect('row9', '3=Page;9=SalesOrder;6=42;12=Yes;13=No;14=No;');
        Observer.Expect('row10', '3=Page;9=UserTaskSetComplete;6=1170;12=Yes;13=No;14=No;');
        Observer.Expect('row11', '3=Query;9=DimensionSets;6=257;12=Yes;13=No;14=No;');
        Observer.Expect('row12', '3=Query;9=ItemSalesAndProfit;6=103;12=Yes;13=No;14=No;');
        Observer.Expect('row13', '3=Query;9=ItemSalesByCustomer;6=102;12=Yes;13=No;14=No;');
        Observer.Expect('row14', '3=Query;9=SalesDashboard;6=101;12=Yes;13=No;14=No;');
        Observer.Expect('row15', '3=Query;9=SalesOpportunities;6=105;12=Yes;13=No;14=No;');
        Observer.Expect('row16', '3=Query;9=SalesOrdersBySalesPerson;6=104;12=Yes;13=No;14=No;');
        Observer.Expect('row17', '3=Query;9=TopCustomerOverview;6=100;12=Yes;13=No;14=No;');
        Observer.Verify();
    end;

    // ---- Writer QX (Microsoft's DemoTool, Create Web Services: WebServiceManagement.CreateWebService(Page, Page::"Sales Order", '', true)):
    // the Web Service and Tenant Web Service rows for page 42 before and after, the name an empty ObjectName gives, a second call, a named call. ----

    local procedure QxRowsFor(ObjectId: Integer): Text
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        Result: Text;
    begin
        WebService.SetRange("Object Type", WebService."Object Type"::Page);
        WebService.SetRange("Object ID", ObjectId);
        if WebService.FindSet() then
            repeat
                Result += 'ws[' + WebService."Service Name" + '|' + Format(WebService.Published) + ']';
            until WebService.Next() = 0;
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", ObjectId);
        if TenantWebService.FindSet() then
            repeat
                Result += 'tws[' + TenantWebService."Service Name" + '|' + Format(TenantWebService.Published) + ']';
            until TenantWebService.Next() = 0;
        exit(Result);
    end;

    local procedure QxCounts(): Text
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
    begin
        exit(Format(WebService.Count()) + '|' + Format(TenantWebService.Count()));
    end;

    [Test]
    procedure QX_CreateWebService_SalesOrderPage()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('counts before', QxCounts());
        Observer.Observe('page 42 before', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", '', true);
        Observer.Observe('counts after', QxCounts());
        Observer.Observe('page 42 after', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", '', false);
        Observer.Observe('page 42 after unpublished call', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", '', true);
        WebServiceManagement.CreateWebService(WebService."Object Type"::Page, Page::"Sales Order", 'LTQXSalesOrder', true);
        Observer.Observe('page 42 after named call', QxRowsFor(Page::"Sales Order"));
        WebServiceManagement.CreateTenantWebService(WebService."Object Type"::Page, Page::"Sales Order", 'LTQXTenantSalesOrder', true);
        Observer.Observe('page 42 after tenant call', QxRowsFor(Page::"Sales Order"));
        Observer.Observe('counts end', QxCounts());
        WebService.SetFilter("Service Name", 'LTQX*');
        WebService.DeleteAll();
        TenantWebService.SetFilter("Service Name", 'LTQX*');
        TenantWebService.DeleteAll();
        Observer.Observe('counts cleaned', QxCounts());
        Observer.Expect('counts before', '17|64');
        Observer.Expect('page 42 before', 'ws[SalesOrder|Yes]');
        Observer.Expect('counts after', '17|64');
        Observer.Expect('page 42 after', 'ws[SalesOrder|Yes]');
        Observer.Expect('page 42 after unpublished call', 'ws[SalesOrder|No]');
        Observer.Expect('page 42 after named call', 'ws[LTQXSalesOrder|Yes]ws[SalesOrder|Yes]');
        Observer.Expect('page 42 after tenant call', 'ws[LTQXSalesOrder|Yes]ws[SalesOrder|Yes]tws[LTQXTenantSalesOrder|Yes]');
        Observer.Expect('counts end', '18|65');
        Observer.Expect('counts cleaned', '17|64');
        Observer.Verify();
    end;
}
