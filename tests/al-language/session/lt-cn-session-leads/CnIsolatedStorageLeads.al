// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 84884 (CnTransferFieldsModify.al); self-contained codeunits 84887-84889, 84892-84893, page 84890, 84898, report 84891
// Probe: corpus issue #669 (writer CN).
//   55 (microsoft/AL#8142): IsolatedStorage.Set, Get, Delete inside a page background task worker, run with TestPage.RunPageBackgroundTask.
//   56 (microsoft/AL#5452): does IsolatedStorage.Set open a write transaction, so that a guarded Codeunit.Run, Page.RunModal or Report.RunModal
//       right after it is refused? And after a Commit?
//   57: the value length limit of IsolatedStorage.SetEncrypted (docs: 215 characters, special characters take more space).
// Keys start with LTCN and are deleted at the start of each test.
// BC versions: 27, 28, 29

codeunit 84887 "LT CN BgTask Iso Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
        Value: Text;
        Row: Record "LT CN TF Row";
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);
        Results.Add('InWriteTx', Format(Database.IsInWriteTransaction(), 0, 9));
        case Op of
            'set':
                Results.Add('Ret', Format(IsolatedStorage.Set('LTCNbg', 'fromtask', DataScope::Module), 0, 9));
            'get':
                begin
                    Results.Add('Ret', Format(IsolatedStorage.Get('LTCNbg', DataScope::Module, Value), 0, 9));
                    Results.Add('Value', Value);
                end;
            'delete':
                Results.Add('Ret', Format(IsolatedStorage.Delete('LTCNbg', DataScope::Module), 0, 9));
            'insert':
                begin
                    Row.Init();
                    Row.Id := 77;
                    Row.Name := 'task';
                    Results.Add('Ret', Format(Row.Insert(), 0, 9));
                end;
        end;
        Results.Add('InWriteTxAfter', Format(Database.IsInWriteTransaction(), 0, 9));
        Page.SetBackgroundTaskResult(Results);
    end;
}

page 84898 "LT CN BgTask Card"
{
    PageType = Card;
    SourceTable = "LT CN TF Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

codeunit 84888 "LT CN BgTask Iso"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Row: Record "LT CN TF Row";
    begin
        if IsolatedStorage.Contains('LTCNbg', DataScope::Module) then
            IsolatedStorage.Delete('LTCNbg', DataScope::Module);
        Row.DeleteAll();
        Commit();
    end;

    local procedure RunTask(Op: Text; var Observer: Codeunit "Probe Observer")
    var
        Card: TestPage "LT CN BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        K: Text;
    begin
        Params.Add('Op', Op);
        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"LT CN BgTask Iso Worker", Params, false);
        Card.Close();
        foreach K in Results.Keys() do
            Observer.Observe(Op + ' ' + K, Results.Get(K));
    end;

    [Test]
    procedure BgTask_IsolatedStorageSet()
    var
        Observer: Codeunit "Probe Observer";
        Value: Text;
    begin
        Clean();
        RunTask('set', Observer);
        Observer.Observe('contains after', Format(IsolatedStorage.Contains('LTCNbg', DataScope::Module)));
        if IsolatedStorage.Get('LTCNbg', DataScope::Module, Value) then
            Observer.Observe('value after', Value);
        Observer.Finish();
    end;

    [Test]
    procedure BgTask_IsolatedStorageGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNbg', 'seeded', DataScope::Module);
        Commit();
        RunTask('get', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure BgTask_IsolatedStorageDelete()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNbg', 'seeded', DataScope::Module);
        Commit();
        RunTask('delete', Observer);
        Observer.Observe('contains after', Format(IsolatedStorage.Contains('LTCNbg', DataScope::Module)));
        Observer.Finish();
    end;

    [Test]
    procedure BgTask_RecordInsert_Control()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CN TF Row";
    begin
        Clean();
        RunTask('insert', Observer);
        Observer.Observe('row after', Format(Row.Get(77)));
        Observer.Finish();
    end;
}

codeunit 84889 "LT CN Noop"
{
    trigger OnRun()
    begin
    end;
}

page 84890 "LT CN Modal Page"
{
    PageType = Card;
    UsageCategory = None;
    SourceTable = "LT CN TF Row";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

report 84891 "LT CN Proc Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(N; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

codeunit 84892 "LT CN Iso WriteTx"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ModalSeen: Integer;

    local procedure Clean()
    begin
        if IsolatedStorage.Contains('LTCNtx', DataScope::User) then
            IsolatedStorage.Delete('LTCNtx', DataScope::User);
        if IsolatedStorage.Contains('LTCNtx', DataScope::Module) then
            IsolatedStorage.Delete('LTCNtx', DataScope::Module);
        Commit();
    end;

    [Test]
    procedure IsoSet_OpensWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Observer.Observe('before', Format(Database.IsInWriteTransaction()));
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Observer.Observe('after set user', Format(Database.IsInWriteTransaction()));
        Commit();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::Module);
        Observer.Observe('after set module', Format(Database.IsInWriteTransaction()));
        Commit();
        IsolatedStorage.Delete('LTCNtx', DataScope::Module);
        Observer.Observe('after delete', Format(Database.IsInWriteTransaction()));
        Commit();
        Observer.Observe('contains', Format(IsolatedStorage.Contains('LTCNtx', DataScope::User)));
        Observer.Observe('after contains', Format(Database.IsInWriteTransaction()));
        Observer.Finish();
    end;

    [Test]
    procedure IsoSet_ThenGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Observer.Observe('run', Format(Codeunit.Run(Codeunit::"LT CN Noop")));
        Observer.Finish();
    end;

    [Test]
    procedure IsoSet_Commit_ThenGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Commit();
        Observer.Observe('run', Format(Codeunit.Run(Codeunit::"LT CN Noop")));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ModalHandler')]
    procedure IsoSet_ThenPageRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        ModalSeen := 0;
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Observer.Observe('action', Format(Page.RunModal(Page::"LT CN Modal Page")));
        Observer.Observe('handler calls', Format(ModalSeen));
        Observer.Finish();
    end;

    [Test]
    procedure IsoSet_ThenReportRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        IsolatedStorage.Set('LTCNtx', 'v', DataScope::User);
        Report.RunModal(Report::"LT CN Proc Report", false);
        Observer.Observe('reached', 'yes');
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ModalHandler(var P: TestPage "LT CN Modal Page")
    begin
        ModalSeen += 1;
        P.OK().Invoke();
    end;
}

codeunit 84893 "LT CN SetEncrypted Len"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    begin
        if IsolatedStorage.Contains('LTCNenc', DataScope::Module) then
            IsolatedStorage.Delete('LTCNenc', DataScope::Module);
    end;

    local procedure TrySet(Value: Text; var Observer: Codeunit "Probe Observer")
    var
        Back: Text;
    begin
        Clean();
        Observer.Observe('ret', Format(IsolatedStorage.SetEncrypted('LTCNenc', Value, DataScope::Module)));
        Observer.Observe('contains', Format(IsolatedStorage.Contains('LTCNenc', DataScope::Module)));
        if IsolatedStorage.Get('LTCNenc', DataScope::Module, Back) then
            Observer.Observe('same back', Format(Back = Value));
        Clean();
    end;

    [Test]
    procedure SetEncrypted_EncryptionEnabled()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('encryption enabled', Format(EncryptionEnabled()));
        Observer.Finish();
    end;

    [Test]
    procedure SetEncrypted_215Ascii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrySet(PadStr('', 215, 'a'), Observer);
        Observer.Finish();
    end;

    [Test]
    procedure SetEncrypted_216Ascii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrySet(PadStr('', 216, 'a'), Observer);
        Observer.Finish();
    end;

    [Test]
    procedure SetEncrypted_108NonAscii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrySet(PadStr('', 108, 'é'), Observer);
        Observer.Finish();
    end;

    [Test]
    procedure SetEncrypted_1000Ascii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrySet(PadStr('', 1000, 'a'), Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Set_Plain_1000Ascii_Control()
    var
        Observer: Codeunit "Probe Observer";
        Back: Text;
    begin
        Clean();
        Observer.Observe('ret', Format(IsolatedStorage.Set('LTCNenc', PadStr('', 1000, 'a'), DataScope::Module)));
        IsolatedStorage.Get('LTCNenc', DataScope::Module, Back);
        Observer.Observe('len back', Format(StrLen(Back)));
        Clean();
        Observer.Finish();
    end;
}
