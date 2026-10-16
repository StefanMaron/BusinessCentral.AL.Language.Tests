// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.Open: temporary flag, company name, wrong ids, reopen on the same variable
// BC versions: 29 (27 and 28 by CI)

codeunit 72210 "LT P92 Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOpen(TableNo: Integer; Temp: Boolean; Company: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo, Temp, Company);
    end;

    [TryFunction]
    local procedure TryOpenPlain(TableNo: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error|' + GetLastErrorCode() + '|' + Format(StrPos(GetLastErrorText(), 'does not exist') > 0));
    end;

    [Test]
    procedure Open_TemporaryIsolatedFromReal()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Real: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        RecRef.Open(72200, true);
        Observer.Observe('temp_isTemp', Format(RecRef.IsTemporary()));
        Observer.Observe('temp_count0', Format(RecRef.Count()));
        RecRef.Field(1).Value := 'T1';
        Observer.Observe('temp_insert1', Format(RecRef.Insert()));
        RecRef.Init();
        RecRef.Field(1).Value := 'T2';
        Observer.Observe('temp_insert2', Format(RecRef.Insert()));
        Observer.Observe('temp_count2', Format(RecRef.Count()));
        Observer.Observe('real_count', Format(Real.Count()));
        Observer.Observe('real_hasT1', Format(Real.Get('T1')));
        asserterror RecRef.Insert();
        Observer.ObserveError('temp_dupkey');
        RecRef.DeleteAll();
        Observer.Observe('temp_count_after_deleteall', Format(RecRef.Count()));
        Observer.Observe('real_count_after', Format(Real.Count()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Open_TemporaryFlagIgnoresCompany()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72200, true, CompanyName());
        Observer.Observe('own_company_temp', Format(RecRef.IsTemporary()));
        RecRef.Close();
        RecRef.Open(72200, false, CompanyName());
        Observer.Observe('own_company_real', Format(RecRef.IsTemporary()));
        RecRef.Close();
        Observer.Observe('unknown_company_real', Outcome(TryOpen(72200, false, 'No Such Company P92')));
        Observer.Observe('unknown_company_temp', Outcome(TryOpen(72200, true, 'No Such Company P92')));
        Observer.Observe('blank_company_real', Outcome(TryOpen(72200, false, '')));
        Observer.Observe('blank_company_temp', Outcome(TryOpen(72200, true, '')));
        Observer.Observe('space_company', Outcome(TryOpen(72200, false, ' ')));
        Observer.Observe('lowercase_company', Outcome(TryOpen(72200, false, LowerCase(CompanyName()))));
        Observer.Observe('uppercase_company', Outcome(TryOpen(72200, false, UpperCase(CompanyName()))));
        Observer.Observe('long_company', Outcome(TryOpen(72200, false, PadStr('', 300, 'x'))));
        Observer.Finish();
    end;

    [Test]
    procedure Open_ErrorTextUnknownCompany()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        asserterror RecRef.Open(72200, false, 'P92 Missing Co');
        Observer.ObserveError('missing_company');
        asserterror RecRef.Open(72200, false, 'P92 Missing Co "quoted"');
        Observer.ObserveError('missing_company_quoted');
        asserterror RecRef.Open(72200, false, PadStr('', 40, 'z'));
        Observer.ObserveError('missing_company_long');
        Observer.Observe('still_closed_number', Format(RecRef.Number()));
        Observer.Finish();
    end;

    [Test]
    procedure Open_WrongIds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('zero', Outcome(TryOpenPlain(0)));
        Observer.Observe('negative', Outcome(TryOpenPlain(-5)));
        Observer.Observe('unused_id', Outcome(TryOpenPlain(72299)));
        Observer.Observe('codeunit_id', Outcome(TryOpenPlain(72209)));
        Observer.Observe('maxint', Outcome(TryOpenPlain(2147483647)));
        Observer.Observe('minint', Outcome(TryOpenPlain(-2147483647)));
        Observer.Observe('temp_unused_id', Outcome(TryOpen(72299, true, '')));
        Observer.Observe('temp_codeunit_id', Outcome(TryOpen(72209, true, '')));
        Observer.Finish();
    end;

    [Test]
    procedure Open_FailedOpenKeepsPreviousState()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(72200);
        asserterror RecRef.Open(72299);
        Observer.ObserveError('failed_reopen');
        Observer.Observe('number_after_failed', Format(RecRef.Number()));
        Observer.Observe('name_after_failed', RecRef.Name());
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Open_CloseThenReopenKeepsCurrentRecord()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.FindLast();
        Observer.Observe('last_code', Format(RecRef.Field(1).Value));
        RecRef.Close();
        RecRef.Open(72200);
        Observer.Observe('after_reopen_code', Format(RecRef.Field(1).Value));
        Observer.Observe('after_reopen_pos', RecRef.GetPosition());
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Open_NumberNameCaptionByVariants()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Rec: Record "LT P92 Item";
    begin
        RecRef.Open(72201);
        Observer.Observe('pair_number', Format(RecRef.Number()));
        Observer.Observe('pair_name', RecRef.Name());
        Observer.Observe('pair_caption', RecRef.Caption());
        RecRef.Close();
        RecRef.Open(DATABASE::"LT P92 Item");
        Observer.Observe('item_number', Format(RecRef.Number()));
        Observer.Observe('item_caption', RecRef.Caption());
        Observer.Observe('item_istemp_by_default', Format(RecRef.IsTemporary()));
        RecRef.Close();
        RecRef.GetTable(Rec);
        Observer.Observe('gettable_number', Format(RecRef.Number()));
        RecRef.Close();
        Observer.Finish();
    end;
}
