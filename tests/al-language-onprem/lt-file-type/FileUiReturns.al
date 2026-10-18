// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File UI members (RISKY: may raise)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins the return value and the outputs of File.Download, File.DownloadFromStream, File.Upload, both File.UploadIntoStream forms, File.View and File.ViewFromStream when no client handles the dialog. The return variable is set to true before each call, so an untouched variable shows as ret=Yes.
// BC versions: 29 (27 and 28 by CI)
codeunit 61282 "LT Q File Ui Returns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ErrHead(T: Text): Text
    var
        P1: Integer;
        P2: Integer;
        Cut: Integer;
    begin
        P1 := StrPos(T, '/');
        P2 := StrPos(T, '''');
        Cut := P1;
        if (Cut = 0) or ((P2 > 0) and (P2 < Cut)) then
            Cut := P2;
        if Cut > 0 then
            exit(CopyStr(T, 1, Cut - 1));
        exit(CopyStr(T, 1, 200));
    end;

    local procedure TempName(): Text
    begin
        exit(TemporaryPath() + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp');
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure Rec(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; R: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok ret=' + Format(R))
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TDownload(From: Text; Title: Text; Folder: Text; Filter: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.Download(From, Title, Folder, Filter, ToFile);
    end;

    [TryFunction]
    local procedure TDownloadStream(var InS: InStream; Title: Text; Folder: Text; Filter: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.DownloadFromStream(InS, Title, Folder, Filter, ToFile);
    end;

    [TryFunction]
    local procedure TUpload(Title: Text; Folder: Text; Filter: Text; FromFile: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.Upload(Title, Folder, Filter, FromFile, ToFile);
    end;

    [TryFunction]
    local procedure TUploadIntoStream4(Title: Text; Folder: Text; Filter: Text; var FromFile: Text; var InS: InStream; var R: Boolean)
    begin
        R := File.UploadIntoStream(Title, Folder, Filter, FromFile, InS);
    end;

    [TryFunction]
    local procedure TUploadIntoStream2(Filter: Text; var InS: InStream; var R: Boolean)
    begin
        R := File.UploadIntoStream(Filter, InS);
    end;

    [TryFunction]
    local procedure TView(FromFile: Text; Allow: Boolean; var R: Boolean)
    begin
        R := File.View(FromFile, Allow);
    end;

    [TryFunction]
    local procedure TViewFromStream(var InS: InStream; Name: Text; Allow: Boolean; var R: Boolean)
    begin
        R := File.ViewFromStream(InS, Name, Allow);
    end;

#if BC28PLUS
    [Test]
    procedure Download_NoClient_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
        ToFile: Text;
        R: Boolean;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('download content');
        F.Close();
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_title', TDownload(P, 'Title', '', '', ToFile, R), R);
        Observer.Observe('dl_title_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_all_args', TDownload(P, 'Title', TemporaryPath(), 'Text files (*.txt)|*.txt', ToFile, R), R);
        Observer.Observe('dl_all_args_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_blank', TDownload(P, '', '', '', ToFile, R), R);
        Observer.Observe('dl_blank_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_missing', TDownload(P + '.missing', 'Title', '', '', ToFile, R), R);
        Observer.Observe('dl_missing_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_blank_from', TDownload('', 'Title', '', '', ToFile, R), R);
        Observer.Observe('dl_blank_from_tofile', '[' + ToFile + ']');
        Observer.Observe('source_still_exists', Format(File.Exists(P)));
        Cleanup(P);
        Observer.Expect('dl_title', 'ok ret=No');
        Observer.Expect('dl_title_tofile', '[untouched]');
        Observer.Expect('dl_all_args', 'ok ret=No');
        Observer.Expect('dl_all_args_tofile', '[untouched]');
        Observer.Expect('dl_blank', 'ok ret=No');
        Observer.Expect('dl_blank_tofile', '[untouched]');
        Observer.Expect('dl_missing', 'ok ret=No');
        Observer.Expect('dl_missing_tofile', '[untouched]');
        Observer.Expect('dl_blank_from', 'ok ret=No');
        Observer.Expect('dl_blank_from_tofile', '[untouched]');
        Observer.Expect('source_still_exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DownloadFromStream_NoClient_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
        R: Boolean;
    begin
        F.CreateTempFile();
        F.CreateOutStream(OutS);
        OutS.WriteText('stream content');
        F.CreateInStream(InS);
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dls_title', TDownloadStream(InS, 'Title', '', '', ToFile, R), R);
        Observer.Observe('dls_title_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dls_all_args', TDownloadStream(InS, 'Title', TemporaryPath(), 'Text files (*.txt)|*.txt', ToFile, R), R);
        Observer.Observe('dls_all_args_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dls_blank', TDownloadStream(InS, '', '', '', ToFile, R), R);
        Observer.Observe('dls_blank_tofile', '[' + ToFile + ']');
        Observer.Observe('stream_eos_after', Format(InS.EOS()));
        F.Close();
        Observer.Expect('dls_title', 'ok ret=No');
        Observer.Expect('dls_title_tofile', '[untouched]');
        Observer.Expect('dls_all_args', 'ok ret=No');
        Observer.Expect('dls_all_args_tofile', '[untouched]');
        Observer.Expect('dls_blank', 'ok ret=No');
        Observer.Expect('dls_blank_tofile', '[untouched]');
        Observer.Expect('stream_eos_after', 'No');
        Observer.Verify();
    end;
#else
    [Test]
    procedure Download_NoClient_RaisesClrException()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
        ToFile: Text;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('download content');
        F.Close();
        ToFile := 'untouched';
        asserterror File.Download(P, 'Title', '', '', ToFile);
        Observer.Observe('dl_error', CopyStr(GetLastErrorText(), 1, 90));
        Observer.Observe('dl_code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('dl_tofile', '[' + ToFile + ']');
        Cleanup(P);
        Observer.Finish();
    end;

    [Test]
    procedure DownloadFromStream_NoClient_RaisesClrException()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
    begin
        F.CreateTempFile();
        F.CreateOutStream(OutS);
        OutS.WriteText('stream content');
        F.CreateInStream(InS);
        ToFile := 'untouched';
        asserterror File.DownloadFromStream(InS, 'Title', '', '', ToFile);
        Observer.Observe('dls_error', CopyStr(GetLastErrorText(), 1, 90));
        Observer.Observe('dls_code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('dls_tofile', '[' + ToFile + ']');
        F.Close();
        Observer.Finish();
    end;
#endif

    [Test]
    procedure Upload_NoClient_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        ToFile: Text;
        R: Boolean;
    begin
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'up_title', TUpload('Title', '', '', '', ToFile, R), R);
        Observer.Observe('up_title_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'up_all_args', TUpload('Title', TemporaryPath(), 'Text files (*.txt)|*.txt', 'a.txt', ToFile, R), R);
        Observer.Observe('up_all_args_tofile', '[' + ToFile + ']');
        Observer.Expect('up_title', 'ok ret=No');
        Observer.Expect('up_title_tofile', '[untouched]');
        Observer.Expect('up_all_args', 'ok ret=No');
        Observer.Expect('up_all_args_tofile', '[untouched]');
        Observer.Verify();
    end;

    [Test]
    procedure UploadIntoStream_DialogForm_NoClient_ReturnAndFromFile()
    var
        Observer: Codeunit "Probe Observer";
        FromFile: Text;
        InS: InStream;
        R: Boolean;
    begin
        R := true;
        FromFile := 'untouched';
        Rec(Observer, 'uis_title', TUploadIntoStream4('Title', '', '', FromFile, InS, R), R);
        Observer.Observe('uis_title_fromfile', '[' + FromFile + ']');
        R := true;
        FromFile := 'untouched';
        Rec(Observer, 'uis_filter', TUploadIntoStream4('', '', 'Text files (*.txt)|*.txt', FromFile, InS, R), R);
        Observer.Observe('uis_filter_fromfile', '[' + FromFile + ']');
        Observer.Expect('uis_title', 'ok ret=No');
        Observer.Expect('uis_title_fromfile', '[untouched]');
        Observer.Expect('uis_filter', 'ok ret=No');
        Observer.Expect('uis_filter_fromfile', '[untouched]');
        Observer.Verify();
    end;

    [Test]
    procedure UploadIntoStream_FilterForm_NoClient_Return()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        R: Boolean;
    begin
        R := true;
        Rec(Observer, 'uis2_blank', TUploadIntoStream2('', InS, R), R);
        R := true;
        Rec(Observer, 'uis2_txt', TUploadIntoStream2('Text files (*.txt)|*.txt', InS, R), R);
        Observer.Expect('uis2_blank', 'ok ret=No');
        Observer.Expect('uis2_txt', 'ok ret=No');
        Observer.Verify();
    end;

    [Test]
    procedure View_NoClient_Return()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
        R: Boolean;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('view content');
        F.Close();
        R := true;
        Rec(Observer, 'view_existing', TView(P, true, R), R);
        R := true;
        Rec(Observer, 'view_existing_disallow', TView(P, false, R), R);
        R := true;
        Rec(Observer, 'view_missing', TView(P + '.missing', true, R), R);
        R := true;
        Rec(Observer, 'view_blank', TView('', true, R), R);
        Cleanup(P);
        Observer.Expect('view_existing', 'ok ret=No');
        Observer.Expect('view_existing_disallow', 'ok ret=No');
        Observer.Expect('view_missing', 'ok ret=No');
        Observer.Expect('view_blank', 'ok ret=No');
        Observer.Verify();
    end;

    [Test]
    procedure ViewFromStream_NoClient_Return()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        InS: InStream;
        R: Boolean;
    begin
        F.CreateTempFile();
        F.CreateOutStream(OutS);
        OutS.WriteText('stream content');
        F.CreateInStream(InS);
        R := true;
        Rec(Observer, 'vfs_allow', TViewFromStream(InS, 'q.txt', true, R), R);
        R := true;
        Rec(Observer, 'vfs_disallow', TViewFromStream(InS, 'q.txt', false, R), R);
        R := true;
        Rec(Observer, 'vfs_blank_name', TViewFromStream(InS, '', true, R), R);
        F.Close();
        Observer.Expect('vfs_allow', 'ok ret=No');
        Observer.Expect('vfs_disallow', 'ok ret=No');
        Observer.Expect('vfs_blank_name', 'ok ret=No');
        Observer.Verify();
    end;
}
