// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-append-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74768, codeunit 74795
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: TextBuilder.Append of a Variant that holds a blank Date (0D), a Date, a Decimal (also 0, negative, with many decimals), a DateTime (also 0DT), a Time, a Boolean,
//   an Integer, a Text and a Code, and Format of the same Variant. Then the same through RecordRef.FieldIndex(i).Value() of a record with one field of each type
//   (the way Assert.RecordCount in the Microsoft test libraries builds its error text).
// BC versions: all (CI)

table 74768 "LT TBV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; Dec; Decimal) { }
        field(4; Dt; DateTime) { }
        field(5; Tm; Time) { }
        field(6; Flag; Boolean) { }
        field(7; Cde; Code[10]) { }
        field(8; Txt; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74795 "LT TBV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAppend(var TB: TextBuilder; V: Variant)
    begin
        TB.Append(V);
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Tag: Text; V: Variant)
    var
        TB: TextBuilder;
        Ok: Boolean;
    begin
        Ok := TryAppend(TB, V);
        if Ok then
            Observer.Observe(Tag + '.append', '[' + TB.ToText() + ']')
        else begin
            Observer.Observe(Tag + '.append', 'error');
            Observer.ObserveError(Tag + '.appendErr');
        end;
        Observer.Observe(Tag + '.format', '[' + Format(V) + ']');
    end;

    [Test]
    procedure Variant_Dates()
    var
        Observer: Codeunit "Probe Observer";
        BlankDate: Date;
        SomeDate: Date;
        BlankDt: DateTime;
        SomeDt: DateTime;
        SomeTime: Time;
    begin
        SomeDate := DMY2Date(5, 3, 2024);
        SomeDt := CreateDateTime(SomeDate, 143015T);
        SomeTime := 143015T;
        Both(Observer, 'blankDate', BlankDate);
        Both(Observer, 'date', SomeDate);
        Both(Observer, 'blankDateTime', BlankDt);
        Both(Observer, 'dateTime', SomeDt);
        Both(Observer, 'time', SomeTime);
        Observer.Finish();
    end;

    [Test]
    procedure Variant_Decimals()
    var
        Observer: Codeunit "Probe Observer";
        Dec: Decimal;
    begin
        Dec := 0;
        Both(Observer, 'decimal0', Dec);
        Dec := 1.5;
        Both(Observer, 'decimal1.5', Dec);
        Dec := -1234567.891;
        Both(Observer, 'decimalNeg', Dec);
        Dec := 0.1234567890123;
        Both(Observer, 'decimalLong', Dec);
        Observer.Finish();
    end;

    [Test]
    procedure Variant_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        Cde: Code[10];
    begin
        Both(Observer, 'boolTrue', true);
        Both(Observer, 'boolFalse', false);
        Both(Observer, 'integer', 42);
        Both(Observer, 'text', 'text');
        Cde := 'abc';
        Both(Observer, 'code', Cde);
        Observer.Finish();
    end;

    [Test]
    procedure RecordRef_FieldIndexValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TBV Row";
        RR: RecordRef;
        FR: FieldRef;
        TB: TextBuilder;
        i: Integer;
        Ok: Boolean;
    begin
        Row.Init();
        Row.Id := 1;
        RR.GetTable(Row);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Clear(TB);
            Ok := TryAppend(TB, FR.Value());
            Observer.Observe('blank.' + FR.Name(), Format(Ok) + ' [' + TB.ToText() + '] format=[' + Format(FR.Value()) + ']');
        end;
        Row.D := DMY2Date(5, 3, 2024);
        Row.Dec := 1.5;
        Row.Dt := CreateDateTime(DMY2Date(5, 3, 2024), 143015T);
        Row.Tm := 143015T;
        Row.Flag := true;
        Row.Cde := 'abc';
        Row.Txt := 'text';
        RR.GetTable(Row);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Clear(TB);
            Ok := TryAppend(TB, FR.Value());
            Observer.Observe('set.' + FR.Name(), Format(Ok) + ' [' + TB.ToText() + '] format=[' + Format(FR.Value()) + ']');
        end;
        Observer.Expect('blank.Id', 'No [] format=[1]');
        Observer.Expect('blank.D', 'No [] format=[]');
        Observer.Expect('blank.Dec', 'No [] format=[0]');
        Observer.Expect('blank.Dt', 'No [] format=[]');
        Observer.Expect('blank.Tm', 'No [] format=[]');
        Observer.Expect('blank.Flag', 'No [] format=[No]');
        Observer.Expect('blank.Cde', 'Yes [] format=[]');
        Observer.Expect('blank.Txt', 'Yes [] format=[]');
        Observer.Expect('set.Id', 'No [] format=[1]');
        Observer.Expect('set.D', 'No [] format=[03/05/24]');
        Observer.Expect('set.Dec', 'No [] format=[1.5]');
        Observer.Expect('set.Dt', 'No [] format=[03/05/24 02:30 PM]');
        Observer.Expect('set.Tm', 'No [] format=[ 2:30:15 PM]');
        Observer.Expect('set.Flag', 'No [] format=[Yes]');
        Observer.Expect('set.Cde', 'Yes [ABC] format=[ABC]');
        Observer.Expect('set.Txt', 'Yes [text] format=[text]');
        Observer.Verify();
    end;
}
