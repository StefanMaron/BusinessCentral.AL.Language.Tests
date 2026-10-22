// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: self-contained codeunit 69560
// Probe: observed on the CI legs of BC 27.0, 27.3, 27.5, 28.0, 28.1 to 28.5 and 29.0 (matrix run 38698070659). The Feature Key table is a platform table whose rows differ per minor, so the
// rows are pinned PER VERSION and the row test does nothing on a version that was not measured.
//
// - The table has the same 10 fields on every measured version: 1=ID(Text) 2=Enabled(Option) 3=Description(Text) 4=Learn More Link(Text) 5=Mandatory By(Text) 6=Can Try(Boolean)
//   7=Is One Way(Boolean) 8=Data Update Required(Boolean) 9=Mandatory By Version(Text) 10=Description In English(Text). There is NO field "Mandatory" and NO field "Will Be Enabled On"
//   (also not in the temporary table "Feature Key Buffer" of the System Application); "Mandatory By" is the text of the wave, "Mandatory By Version" the version.
// - Rows (ID: Enabled, Mandatory By Version, Can Try, Is One Way, Data Update Required): 16 rows on 27.0 to 27.5 (27.0 reads SemanticMetadataSearch Enabled None, 27.3 and 27.5 All Users),
//   14 on 28.x (28.0 differs from 28.1 to 28.5 in the rows' Mandatory By), 13 on 29.0.
// BC versions: 27.0, 27.3, 27.5, 28.0, 28.1 to 28.5, 29.0
codeunit 69560 "PF Feature Key Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FieldValue(var RecRef: RecordRef; FieldName: Text): Text
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Name() = FieldName then
                exit(Format(FldRef.Value()));
        end;
        exit('<no such field>');
    end;

    local procedure RowText(var RecRef: RecordRef): Text
    begin
        exit('Enabled=' + FieldValue(RecRef, 'Enabled') +
            ' | Mandatory By=' + FieldValue(RecRef, 'Mandatory By') +
            ' | Mandatory By Version=' + FieldValue(RecRef, 'Mandatory By Version') +
            ' | Can Try=' + FieldValue(RecRef, 'Can Try') +
            ' | Is One Way=' + FieldValue(RecRef, 'Is One Way') +
            ' | Data Update Required=' + FieldValue(RecRef, 'Data Update Required'));
    end;

    local procedure ExpectedRows(var Expected: Dictionary of [Text, Text]): Boolean
    var
        AppConstants: Codeunit "Application System Constants";
        Version: Text;
    begin
        Version := AppConstants.ApplicationVersion();
        // The text starts with the country ('W1 29.0' or 'W1 29.0.54011.0'): keep the version.
        if Version.Contains(' ') then
            Version := CopyStr(Version, StrPos(Version, ' ') + 1);
        // It may be only major.minor ('29.0'): the dot makes the prefix tests below work either way.
        Version += '.';
        if Version.StartsWith('27.0.') then begin
            RowsA(Expected);
            exit(true);
        end;
        if Version.StartsWith('27.3.') then begin
            RowsB(Expected);
            exit(true);
        end;
        if Version.StartsWith('27.5.') then begin
            RowsB(Expected);
            exit(true);
        end;
        if Version.StartsWith('28.0.') then begin
            RowsC(Expected);
            exit(true);
        end;
        if Version.StartsWith('28.1.') then begin
            RowsD(Expected);
            exit(true);
        end;
        if Version.StartsWith('28.2.') then begin
            RowsD(Expected);
            exit(true);
        end;
        if Version.StartsWith('28.3.') then begin
            RowsD(Expected);
            exit(true);
        end;
        if Version.StartsWith('28.4.') then begin
            RowsD(Expected);
            exit(true);
        end;
        if Version.StartsWith('28.5.') then begin
            RowsD(Expected);
            exit(true);
        end;
        if Version.StartsWith('29.0.') then begin
            RowsE(Expected);
            exit(true);
        end;
        exit(false);
    end;

    local procedure RowsA(var Rows: Dictionary of [Text, Text])
    begin
        Rows.Add('AdvancedTellMe', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('CalcOnlyVisibleFlowFields', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcealedMaskType', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentInventoryPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentJobPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentResourcePosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('DisableSoapWebServicesOnMicrosoftUIPages', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('EnableMcpAccess', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('FinancialReportDefaults', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FullTextSearch', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('GLCurrencyRevaluation', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('Manufacturing_FlushingMethod_ActivateManualWoPick', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('ReminderTermsCommunicationTexts', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('SalesPrices', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('SaveValueToDatabasePromptly', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('SemanticMetadataSearch', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
    end;

    local procedure RowsB(var Rows: Dictionary of [Text, Text])
    begin
        Rows.Add('AdvancedTellMe', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('CalcOnlyVisibleFlowFields', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcealedMaskType', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentInventoryPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentJobPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentResourcePosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('DisableSoapWebServicesOnMicrosoftUIPages', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('EnableMcpAccess', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('FinancialReportDefaults', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FullTextSearch', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('GLCurrencyRevaluation', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('Manufacturing_FlushingMethod_ActivateManualWoPick', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('ReminderTermsCommunicationTexts', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('SalesPrices', 'Enabled=None | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('SaveValueToDatabasePromptly', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('SemanticMetadataSearch', 'Enabled=All Users | Mandatory By=2026 Wave 1 (from April to September 2026) | Mandatory By Version=28.0 | Can Try=No | Is One Way=No | Data Update Required=No');
    end;

    local procedure RowsC(var Rows: Dictionary of [Text, Text])
    begin
        Rows.Add('AdvancedTellMe', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcealedMaskType', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentInventoryPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentJobPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentResourcePosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('DisableSoapWebServicesOnMicrosoftUIPages', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('EXRPerformantTrialBalance', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FinancialReportDefaults', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FullTextSearch', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('Manufacturing_FlushingMethod_ActivateManualWoPick', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('ReminderTermsCommunicationTexts', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('SalesPrices', 'Enabled=None | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('SaveValueToDatabasePromptly', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('SemanticMetadataSearch', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
    end;

    local procedure RowsD(var Rows: Dictionary of [Text, Text])
    begin
        Rows.Add('AdvancedTellMe', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcealedMaskType', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentInventoryPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentJobPosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentResourcePosting', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('DisableSoapWebServicesOnMicrosoftUIPages', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('EXRPerformantTrialBalance', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FinancialReportDefaults', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FullTextSearch', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('Manufacturing_FlushingMethod_ActivateManualWoPick', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('ReminderTermsCommunicationTexts', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('SalesPrices', 'Enabled=None | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('SaveValueToDatabasePromptly', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('SemanticMetadataSearch', 'Enabled=None | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
    end;

    local procedure RowsE(var Rows: Dictionary of [Text, Text])
    begin
        Rows.Add('AcceleratedDepreciation', 'Enabled=None | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('AdvancedTellMe', 'Enabled=All Users | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentInventoryPosting', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentJobPosting', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('ConcurrentResourcePosting', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('DisableSoapWebServicesOnMicrosoftUIPages', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('DocumentReportExperience', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No');
        Rows.Add('EXRPerformantTrialBalance', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FinancialReportDefaults', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('FullTextSearch', 'Enabled=None | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('SalesPrices', 'Enabled=None | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes');
        Rows.Add('SaveValueToDatabasePromptly', 'Enabled=All Users | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=Yes | Is One Way=No | Data Update Required=No');
        Rows.Add('SemanticMetadataSearch', 'Enabled=All Users | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=No | Is One Way=No | Data Update Required=No');
    end;

    [Test]
    procedure FeatureKey_Fields_AndNoMandatoryColumns()
    var
        FieldRec: Record Field;
        Names: Text;
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, Database::"Feature Key");
        FieldRec.SetFilter("No.", '<2000000000');
        FieldRec.FindSet();
        repeat
            Names += Format(FieldRec."No.") + '=' + FieldRec.FieldName + '(' + Format(FieldRec.Type) + ') ';
        until FieldRec.Next() = 0;
        Observer.Observe('fields', Names);
        RecRef.Open(Database::"Feature Key");
        Observer.Observe('mandatory_field', FieldValue(RecRef, 'Mandatory'));
        Observer.Observe('will_be_enabled_on_field', FieldValue(RecRef, 'Will Be Enabled On'));
        Observer.Expect('fields', '1=ID(Text) 2=Enabled(Option) 3=Description(Text) 4=Learn More Link(Text) 5=Mandatory By(Text) 6=Can Try(Boolean) 7=Is One Way(Boolean) 8=Data Update Required(Boolean) 9=Mandatory By Version(Text) 10=Description In English(Text) ');
        Observer.Expect('mandatory_field', '<no such field>');
        Observer.Expect('will_be_enabled_on_field', '<no such field>');
        Observer.Verify();
    end;

    [Test]
    procedure FeatureKey_RowsPerId_PerMeasuredVersion()
    var
        FeatureKey: Record "Feature Key";
        RecRef: RecordRef;
        Expected: Dictionary of [Text, Text];
        Actual: Dictionary of [Text, Text];
        Id: Text;
        Problems: Text;
        Assert: Codeunit Assert;
    begin
        if not ExpectedRows(Expected) then
            exit;
        FeatureKey.FindSet();
        repeat
            RecRef.GetTable(FeatureKey);
            Actual.Add(FeatureKey.ID, RowText(RecRef));
        until FeatureKey.Next() = 0;
        foreach Id in Expected.Keys() do
            if not Actual.ContainsKey(Id) then
                Problems += ' missing:' + Id
            else
                if Actual.Get(Id) <> Expected.Get(Id) then
                    Problems += ' differs:' + Id + '[' + Actual.Get(Id) + '] expected [' + Expected.Get(Id) + ']';
        foreach Id in Actual.Keys() do
            if not Expected.ContainsKey(Id) then
                Problems += ' unexpected:' + Id;
        Assert.AreEqual('', Problems, 'Feature Key rows');
    end;
}
