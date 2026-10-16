// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: tables 72200, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField / FieldError with ErrorInfo (Record side certain, FieldRef side unsure: drop the FieldRef tests when they do not compile)
// BC versions: 29 (27 and 28 by CI)

codeunit 72224 "LT P92 ErrorInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Record_TestField_ErrorInfo_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        Item: Record "LT P92 Item";
        Info: ErrorInfo;
    begin
        Helper.SeedItems();
        Item.Get('B1');
        Info.Message := 'info message';
        asserterror Item.TestField(Name, Info);
        Observer.ObserveError('rec_blank_info');
        asserterror Item.TestField(Qty, 5, Info);
        Observer.ObserveError('rec_value_info');
        Info.Message := '';
        asserterror Item.TestField(Name, Info);
        Observer.ObserveError('rec_blank_info_emptymsg');
        asserterror Item.TestField(Name);
        Observer.ObserveError('rec_blank_plain');
        Observer.Finish();
    end;

    [Test]
    procedure Record_FieldError_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        Item: Record "LT P92 Item";
        Info: ErrorInfo;
    begin
        Helper.SeedItems();
        Item.Get('A1');
        Info.Message := 'info message';
        asserterror Item.FieldError(Name, Info);
        Observer.ObserveError('rec_fielderror_info');
        Info.Message := '';
        asserterror Item.FieldError(Name, Info);
        Observer.ObserveError('rec_fielderror_info_emptymsg');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_TestField_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(1).SetRange('B1');
        RecRef.FindFirst();
        Info.Message := 'info message';
        Fld := RecRef.Field(2);
        asserterror Fld.TestField(Info);
        Observer.ObserveError('ref_blank_info');
        Fld := RecRef.Field(3);
        asserterror Fld.TestField(5, Info);
        Observer.ObserveError('ref_value_info');
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldRef_FieldError_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(1).SetRange('A1');
        RecRef.FindFirst();
        Info.Message := 'info message';
        Fld := RecRef.Field(2);
        asserterror Fld.FieldError(Info);
        Observer.ObserveError('ref_fielderror_info');
        RecRef.Close();
        Observer.Finish();
    end;
}
