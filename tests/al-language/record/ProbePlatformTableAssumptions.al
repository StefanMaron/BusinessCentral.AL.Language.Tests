// Probe: platform tables read from AL (probes-needed.md "Platform tables (ADR-019)"). Rows are dumped column by column.
// Names containing "EnvData" depend on the tier or tenant: record, do not assert as a constant.
codeunit 69475 "Probe Platform Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Date_PeriodInvariantName_VersusPeriodName()
    var
        DateRec: Record Date;
        Observer: Codeunit "Probe Observer";
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", DMY2Date(15, 3, 2030));
        DateRec.FindFirst();
        Observer.Observe('dayName', DateRec."Period Name");
        Observer.Observe('dayInvariantName', DateRec."Period Invariant Name");
        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        DateRec.SetRange("Period Start", DMY2Date(1, 3, 2030));
        DateRec.FindFirst();
        Observer.Observe('monthName', DateRec."Period Name");
        Observer.Observe('monthInvariantName', DateRec."Period Invariant Name");
        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", DMY2Date(17, 3, 2030));
        DateRec.FindFirst();
        Observer.Observe('sundayName', DateRec."Period Name");
        Observer.Observe('sundayInvariantName', DateRec."Period Invariant Name");
        Observer.Expect('dayName', 'Friday');
        Observer.Expect('dayInvariantName', 'Friday');
        Observer.Expect('monthName', 'March');
        Observer.Expect('monthInvariantName', 'March');
        Observer.Expect('sundayName', 'Sunday');
        Observer.Expect('sundayInvariantName', 'Sunday');
        Observer.Verify();
    end;

    [Test]
    procedure WindowsLanguage_AllColumns_Of_1031_1033_2057_AndRowCount()
    var
        Lang: Record "Windows Language";
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
        Observer: Codeunit "Probe Observer";
        Id: Integer;
        Ids: List of [Integer];
    begin
        Ids.Add(1031);
        Ids.Add(1033);
        Ids.Add(2057);
        Ids.Add(1036);
        Ids.Add(2055);
        Ids.Add(4105);
        Ids.Add(99999);
        foreach Id in Ids do begin
            Clear(Lang);
            if Lang.Get(Id) then begin
                RecRef.GetTable(Lang);
                Observer.Observe('lcid' + Format(Id), Dumper.Dump(RecRef));
            end else
                Observer.Observe('lcid' + Format(Id), '(no row)');
        end;
        Observer.Observe('rowCount_EnvData', Format(Lang.Count()));
        Observer.Expect('lcid99999', '(no row)');
        Observer.Ignore('rowCount_EnvData'); // environment data: observed, not asserted
        Observer.Ignore('lcid1031'); // a dump or environment data: observed, not asserted
        Observer.Ignore('lcid1033'); // a dump or environment data: observed, not asserted
        Observer.Ignore('lcid2057'); // a dump or environment data: observed, not asserted
        Observer.Ignore('lcid1036'); // a dump or environment data: observed, not asserted
        Observer.Ignore('lcid2055'); // a dump or environment data: observed, not asserted
        Observer.Ignore('lcid4105'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure TimeZone_Rows_EnvData()
    var
        TimeZone: Record "Time Zone";
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('count_EnvData', Format(TimeZone.Count()));
        TimeZone.SetFilter(ID, '*UTC*|*GMT*|*W. Europe*|*Eastern*|*Pacific*');
        RecRef.GetTable(TimeZone);
        Observer.Observe('selectedRows_EnvData', Dumper.DumpAll(RecRef, 10));
        Observer.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;

    [Test]
    procedure Session_AllColumns_EnvData()
    var
        SessionRec: Record Session;
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
        Observer: Codeunit "Probe Observer";
    begin
        SessionRec.SetRange("My Session", true);
        RecRef.GetTable(SessionRec);
        Observer.Observe('ownSessionRow_EnvData', Dumper.DumpAll(RecRef, 1));
        Observer.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;

    [Test]
    procedure ActiveSession_AllColumns_EnvData()
    var
        ActiveSession: Record "Active Session";
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
        Observer: Codeunit "Probe Observer";
    begin
        ActiveSession.SetRange("Session ID", SessionId());
        RecRef.GetTable(ActiveSession);
        Observer.Observe('ownActiveSessionRow_EnvData', Dumper.DumpAll(RecRef, 1));
        Observer.Observe('tenantId_EnvData', Database.TenantId());
        Observer.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;





    [Test]
    procedure RecordLink_AddLink_CreatedAndDeleteLinkCompany()
    var
        Row: Record "Probe Pf Row";
        Link: Record "Record Link";
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
        Observer: Codeunit "Probe Observer";
        Before: DateTime;
    begin
        Row.Id := 69450003;
        Row.Insert();
        Before := CurrentDateTime();
        Row.AddLink('https://example.com/probe', 'probe link');
        Link.SetRange("Record ID", Row.RecordId());
        Link.FindFirst();
        RecRef.GetTable(Link);
        Observer.Observe('linkRow', Dumper.Dump(RecRef));
        Observer.Observe('companyOfLink', Link.Company);
        Observer.Observe('sessionCompany', CompanyName());
        Row.DeleteLinks();
        Observer.Observe('linksAfterDeleteLinks', Format(Link.Count()));
        Observer.Expect('companyOfLink', 'CRONUS International Ltd.');
        Observer.Expect('sessionCompany', 'CRONUS International Ltd.');
        Observer.Expect('linksAfterDeleteLinks', '0');
        Observer.Ignore('linkRow'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TrySetReady(Id: Guid)
    begin
        TaskScheduler.SetTaskReady(Id);
    end;

    [TryFunction]
    local procedure TryCancel(Id: Guid)
    begin
        if not TaskScheduler.CancelTask(Id) then
            Error('CancelTask returned false');
    end;

    [Test]
    procedure TenantMedia_Reads_EnvData()
    var
        TenantMedia: Record "Tenant Media";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tenantMediaCount_EnvData', Format(TenantMedia.Count()));
        Observer.Observe('tenantMediaIsEmpty_EnvData', Format(TenantMedia.IsEmpty()));
        Observer.Discard(); // tier dependent: recorded in the manifest, not asserted
    end;
}
