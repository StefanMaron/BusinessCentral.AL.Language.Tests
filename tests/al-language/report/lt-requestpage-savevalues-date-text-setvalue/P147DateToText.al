// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70252, test codeunit 70253
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// to Text and Code variables: the text is observed next to Format(D), with the default language and GlobalLanguage = 1031 (always restored).
// BC versions: 29 (27 and 28 by CI)

table 70252 "LT P147 Dates"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; DT; DateTime) { }
        field(4; T; Time) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70253 "LT P147 Date To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakeText(Value: Text): Text
    begin
        exit(Value);
    end;

    local procedure TakeText30(Value: Text[30]): Text
    begin
        exit(Value);
    end;

    local procedure TakeCode20(Value: Code[20]): Text
    begin
        exit(Value);
    end;

    local procedure TakeVariant(Value: Variant): Text
    var
        Txt: Text;
    begin
        Txt := Value;
        exit(Txt);
    end;

    local procedure DateVariant(Id: Integer; Which: Integer): Variant
    var
        Rec: Record "LT P147 Dates";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Rec.DeleteAll();
        Rec.Id := Id;
        Rec.D := DMY2Date(5, 3, 2024);
        Rec.DT := CreateDateTime(DMY2Date(5, 3, 2024), 134500T);
        Rec.T := 134500T;
        Rec.Insert();
        RecRef.GetTable(Rec);
        FldRef := RecRef.Field(Which);
        exit(FldRef.Value);
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Prefix: Text; V: Variant; FormatText: Text)
    var
        AsText: Text;
        AsCode: Code[20];
    begin
        Observer.Observe(Prefix + ' Format(D)', FormatText);
        Observer.Observe(Prefix + ' Text param', '[' + TakeText(V) + ']');
        Observer.Observe(Prefix + ' Text[30] param', '[' + TakeText30(V) + ']');
        Observer.Observe(Prefix + ' Code[20] param', '[' + TakeCode20(V) + ']');
        Observer.Observe(Prefix + ' Variant param then Text', '[' + TakeVariant(V) + ']');
        AsText := V;
        Observer.Observe(Prefix + ' Text assign', '[' + AsText + ']');
        AsCode := V;
        Observer.Observe(Prefix + ' Code assign', '[' + AsCode + ']');
        Observer.Observe(Prefix + ' Format(Variant)', Format(V));
    end;

    [Test]
    procedure P147_DateVariant_DefaultLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P147 Dates";
        V: Variant;
        D: Date;
    begin
        Rec.DeleteAll();
        V := DateVariant(1, 2);
        D := V;
        asserterror ObserveAll(Observer, 'date', V, Format(D));
        Observer.ObserveError('af99');
        Observer.Observe('is date', Format(V.IsDate()));
        Observer.Expect('date Format(D)', '03/05/24');
        Observer.Expect('af99|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af99|code', 'TypeConversion');
        Observer.Expect('is date', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P147_DateVariant_German()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P147 Dates";
        V: Variant;
        D: Date;
        OldLanguage: Integer;
    begin
        Rec.DeleteAll();
        OldLanguage := GlobalLanguage();
        V := DateVariant(1, 2);
        D := V;
        GlobalLanguage(1031);
        asserterror ObserveAll(Observer, 'de date', V, Format(D));
        Observer.ObserveError('af119');
        GlobalLanguage(OldLanguage);
        Observer.Observe('language restored', Format(GlobalLanguage() = OldLanguage));
        Observer.Expect('de date Format(D)', '03/05/24');
        Observer.Expect('af119|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('af119|code', 'TypeConversion');
        Observer.Expect('language restored', 'Yes');
        Observer.Verify();
    end;
}
