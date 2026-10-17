// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71891
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: RecordRef.Open on system tables in a Cloud-target app: 2000000999 (no such table), 2000000004 (Permission Set), 2000000058 (AllObjWithCaption)
//   and the matching Database:: constants; whether it opens, the Number and Name, or the error text and code. Already pinned in
//   recordref/TestRecordRefOpenCompilationTarget.al: 2000000071 refused, 2000000026, 2000000187 and 2000000188 open.
// BC versions: 27, 28, 29
codeunit 71891 "LT RecordRef Open System"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OpenResult(TableNo: Integer): Text
    var
        Described: Text;
    begin
        ClearLastError();
        if not TryOpen(TableNo, Described) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Described);
    end;

    [TryFunction]
    local procedure TryOpen(TableNo: Integer; var Described: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        Described := 'opened|' + Format(RecRef.Number) + '|' + RecRef.Name();
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Open_SystemTables_ByNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t2000000999', OpenResult(2000000999));
        Observer.Observe('t2000000004', OpenResult(2000000004));
        Observer.Observe('t2000000058', OpenResult(2000000058));
        Observer.Observe('t2000000000', OpenResult(2000000000));
        Observer.Observe('t0', OpenResult(0));
        Observer.Observe('t_negative', OpenResult(-1));
        Observer.Observe('t99999999', OpenResult(99999999));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRef_Open_SystemTables_ByDatabaseConstant()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('permission_set', OpenResult(Database::"Permission Set"));
        Observer.Observe('all_obj_with_caption', OpenResult(Database::AllObjWithCaption));
        Observer.Observe('integer', OpenResult(Database::Integer));
        Observer.Finish();
    end;
}
