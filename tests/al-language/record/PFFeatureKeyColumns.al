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

    [Test]
    procedure FeatureKey_FieldList()
    var
        FieldRec: Record Field;
        Names: Text;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, Database::"Feature Key");
        FieldRec.SetFilter("No.", '<2000000000');
        FieldRec.FindSet();
        repeat
            Names += Format(FieldRec."No.") + '=' + FieldRec.FieldName + '(' + Format(FieldRec.Type) + ') ';
        until FieldRec.Next() = 0;
        Observer.Observe('fields', Names);
        Observer.Finish();
    end;

    [Test]
    procedure FeatureKey_ColumnsPerId()
    var
        FeatureKey: Record "Feature Key";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row_count', Format(FeatureKey.Count()));
        FeatureKey.FindSet();
        repeat
            RecRef.GetTable(FeatureKey);
            Observer.Observe(FeatureKey.ID,
                'Enabled=' + FieldValue(RecRef, 'Enabled') +
                ' | Mandatory=' + FieldValue(RecRef, 'Mandatory') +
                ' | Mandatory By=' + FieldValue(RecRef, 'Mandatory By') +
                ' | Mandatory By Version=' + FieldValue(RecRef, 'Mandatory By Version') +
                ' | Will Be Enabled On=' + FieldValue(RecRef, 'Will Be Enabled On') +
                ' | Can Try=' + FieldValue(RecRef, 'Can Try') +
                ' | Is One Way=' + FieldValue(RecRef, 'Is One Way') +
                ' | Data Update Required=' + FieldValue(RecRef, 'Data Update Required'));
        until FeatureKey.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure FeatureKey_ColumnsPerId_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure FeatureKey_ColumnsPerId_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure FeatureKey_ColumnsPerId_More3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;
}
