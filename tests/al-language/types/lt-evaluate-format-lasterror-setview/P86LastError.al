// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) / GetLastErrorText(false), GetLastErrorCode and the start of GetLastErrorCallStack after Error with ErrorInfo, TestField, FieldError and a record-not-found runtime error
// BC versions: 29 (27 and 28 by CI)

table 73530 "LT P86 Err Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[30]) { DataClassification = CustomerContent; }
        field(3; Amount; Decimal) { DataClassification = CustomerContent; }
        field(4; Info; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 73531 "LT P86 Last Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RaiseInfo(Msg: Text; DC: DataClassification)
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := Msg;
        ErrInfo.DataClassification := DC;
        Error(ErrInfo);
    end;

    [Test]
    procedure ErrorInfo_CustomerContent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror RaiseInfo('secret customer text', DataClassification::CustomerContent);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('hasError', Format(GetLastErrorText() <> ''));
        Observer.ObserveError('after');
        Observer.Observe('cleared_full', GetLastErrorText(false));
        Observer.Observe('cleared_excl', GetLastErrorText(true));
        Observer.Finish();
    end;

    [Test]
    procedure ErrorInfo_OtherClassifications()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror RaiseInfo('system text', DataClassification::SystemMetadata);
        Observer.Observe('sys_excl', GetLastErrorText(true));
        Observer.Observe('sys_full', GetLastErrorText(false));
        Observer.ObserveError('sys');
        asserterror RaiseInfo('org text', DataClassification::OrganizationIdentifiableInformation);
        Observer.Observe('oii_excl', GetLastErrorText(true));
        Observer.ObserveError('oii');
        asserterror RaiseInfo('eui text', DataClassification::EndUserIdentifiableInformation);
        Observer.Observe('eui_excl', GetLastErrorText(true));
        Observer.ObserveError('eui');
        asserterror RaiseInfo('pseudo text', DataClassification::EndUserPseudonymousIdentifiers);
        Observer.Observe('eup_excl', GetLastErrorText(true));
        Observer.ObserveError('eup');
        asserterror RaiseInfo('acc text', DataClassification::AccountData);
        Observer.Observe('acc_excl', GetLastErrorText(true));
        Observer.ObserveError('acc');
        asserterror RaiseInfo('tobe text', DataClassification::ToBeClassified);
        Observer.Observe('tbc_excl', GetLastErrorText(true));
        Observer.ObserveError('tbc');
        Observer.Finish();
    end;

    [Test]
    procedure ErrorInfo_DefaultClassification()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := 'no classification set';
        asserterror Error(ErrInfo);
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('default');
        Observer.Observe('dc', Format(ErrInfo.DataClassification));
        Observer.Finish();
    end;

    [Test]
    procedure ErrorInfo_CustomDimensions()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Dims: Dictionary of [Text, Text];
    begin
        Dims.Add('key1', 'value1');
        Dims.Add('key2', 'value2');
        ErrInfo.Message := 'with dimensions';
        ErrInfo.CustomDimensions := Dims;
        asserterror Error(ErrInfo);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('dims');
        Observer.Observe('count', Format(ErrInfo.CustomDimensions.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure ErrorInfo_DimensionsAndCustomerContent()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Dims: Dictionary of [Text, Text];
    begin
        Dims.Add('k', 'v');
        ErrInfo.Message := 'dims and customer content';
        ErrInfo.CustomDimensions := Dims;
        ErrInfo.DataClassification := DataClassification::CustomerContent;
        asserterror Error(ErrInfo);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.Observe('default_arg', GetLastErrorText());
        Observer.ObserveError('both');
        Observer.Finish();
    end;

    [Test]
    procedure PlainError_Exclude()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('plain %1', 'argument');
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('plain');
        asserterror Error('');
        Observer.Observe('empty_excl', GetLastErrorText(true));
        Observer.ObserveError('empty');
        Observer.Finish();
    end;

    [Test]
    procedure TestField_Exclude()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Info := 'x';
        asserterror Rec.TestField(Name);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('empty_cc');
        asserterror Rec.TestField(Info, 'y');
        Observer.Observe('full2', GetLastErrorText(false));
        Observer.Observe('excl2', GetLastErrorText(true));
        Observer.ObserveError('value_sys');
        Rec.Name := 'Jane';
        asserterror Rec.TestField(Name, 'John');
        Observer.Observe('full3', GetLastErrorText(false));
        Observer.Observe('excl3', GetLastErrorText(true));
        Observer.ObserveError('value_cc');
        asserterror Rec.TestField(Amount);
        Observer.Observe('excl4', GetLastErrorText(true));
        Observer.ObserveError('amount');
        Observer.Finish();
    end;

    [Test]
    procedure FieldError_Exclude()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Name := 'Jane';
        Rec.Info := 'x';
        asserterror Rec.FieldError(Name);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('plain_cc');
        asserterror Rec.FieldError(Name, 'custom message');
        Observer.Observe('excl2', GetLastErrorText(true));
        Observer.ObserveError('custom_cc');
        asserterror Rec.FieldError(Info);
        Observer.Observe('excl3', GetLastErrorText(true));
        Observer.ObserveError('plain_sys');
        asserterror Rec.FieldError(Info, 'custom sys');
        Observer.Observe('excl4', GetLastErrorText(true));
        Observer.ObserveError('custom_sys');
        asserterror Rec.FieldError(Amount);
        Observer.Observe('excl5', GetLastErrorText(true));
        Observer.ObserveError('amount');
        Observer.Finish();
    end;

    [Test]
    procedure RuntimeError_NotFound()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
    begin
        Rec.DeleteAll();
        asserterror Rec.Get(99);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('get');
        asserterror Rec.Get(99);
        Observer.Observe('same_excl', Format(GetLastErrorText(true) = GetLastErrorText(false)));
        Observer.ObserveError('get2');
        Rec."Entry No." := 5;
        asserterror Rec.Delete(true);
        Observer.Observe('delete_excl', GetLastErrorText(true));
        Observer.ObserveError('delete');
        asserterror Rec.Modify(true);
        Observer.Observe('modify_excl', GetLastErrorText(true));
        Observer.ObserveError('modify');
        Observer.Finish();
    end;

    [Test]
    procedure RuntimeError_Other()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
        A: Integer;
        Zero: Integer;
    begin
        Rec.DeleteAll();
        A := 1;
        asserterror A := A div Zero;
        Observer.Observe('div_excl', GetLastErrorText(true));
        Observer.ObserveError('div');
        asserterror Rec.FindFirst();
        Observer.Observe('find_excl', GetLastErrorText(true));
        Observer.ObserveError('find');
        asserterror Rec.FindLast();
        Observer.Observe('findlast_excl', GetLastErrorText(true));
        Observer.ObserveError('findlast');
        Rec."Entry No." := 1;
        Observer.Finish();
    end;

    [Test]
    procedure CallStack_Start()
    var
        Observer: Codeunit "Probe Observer";
        Stack: Text;
    begin
        asserterror Error('stack probe');
        Stack := GetLastErrorCallStack();
        Observer.Observe('has_stack', Format(Stack <> ''));
        Observer.Observe('start', CopyStr(Stack, 1, 20));
        Observer.Observe('mentions_proc', Format(StrPos(Stack, 'CallStack_Start') > 0));
        Observer.Observe('mentions_codeunit', Format(StrPos(Stack, 'LT P86 Last Error') > 0));
        Observer.ObserveError('err');
        Observer.Observe('stack_after_clear', GetLastErrorCallStack());
        Observer.Finish();
    end;

    [Test]
    procedure CallStack_RaisedDeeper()
    var
        Observer: Codeunit "Probe Observer";
        Stack: Text;
    begin
        asserterror RaiseInfo('deeper', DataClassification::SystemMetadata);
        Stack := GetLastErrorCallStack();
        Observer.Observe('start', CopyStr(Stack, 1, 20));
        Observer.Observe('mentions_raise', Format(StrPos(Stack, 'RaiseInfo') > 0));
        Observer.Observe('mentions_test', Format(StrPos(Stack, 'CallStack_RaisedDeeper') > 0));
        Observer.Observe('raise_before_test', Format(StrPos(Stack, 'RaiseInfo') < StrPos(Stack, 'CallStack_RaisedDeeper')));
        Observer.ObserveError('err');
        Observer.Finish();
    end;

    [Test]
    procedure CallStack_NoError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('text', GetLastErrorText(false));
        Observer.Observe('text_excl', GetLastErrorText(true));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('stack', GetLastErrorCallStack());
        Observer.Finish();
    end;
}

