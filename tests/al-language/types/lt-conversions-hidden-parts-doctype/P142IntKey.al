// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74541 "LT P142 Int Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74543 "LT P142 Int Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P142 Int Key";
        Ids: List of [Integer];
        I: Integer;
    begin
        R.DeleteAll();
        Ids.Add(0);
        Ids.Add(42);
        Ids.Add(-1);
        Ids.Add(4);
        Ids.Add(1000);
        Ids.Add(2147483647);
        foreach I in Ids do begin
            Clear(R);
            R.Id := I;
            R.Info := 'row' + Format(I);
            R.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryGet(T: Text; var Found: Boolean; var Got: Integer)
    var
        R: Record "LT P142 Int Key";
    begin
        Found := R.Get(T);
        Got := R.Id;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; T: Text)
    var
        Found: Boolean;
        Got: Integer;
        Ok: Boolean;
    begin
        Got := -777;
        Ok := TryGet(T, Found, Got);
        Observer.Observe(Name, Format(Ok) + '|found=' + Format(Found) + '|id=' + Format(Got));
        if not Ok then
            Observer.Observe(Name + '_err', CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P142_IntKey_TextForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 't0', '0');
        Probe(Observer, 't42', '42');
        Probe(Observer, 'tneg1', '-1');
        Probe(Observer, 'tlead_space', ' 42');
        Probe(Observer, 'ttrail_space', '42 ');
        Probe(Observer, 'tplus42', '+42');
        Probe(Observer, 'tcomma', '4,2');
        Probe(Observer, 'texp', '1e3');
        Probe(Observer, 'tempty', '');
        Probe(Observer, 'tzero_pad', '042');
        Observer.Expect('t0', 'Yes|found=Yes|id=0');
        Observer.Expect('t42', 'Yes|found=Yes|id=42');
        Observer.Expect('tneg1', 'Yes|found=Yes|id=-1');
        Observer.Expect('tlead_space', 'Yes|found=Yes|id=42');
        Observer.Expect('ttrail_space', 'Yes|found=Yes|id=42');
        Observer.Expect('tplus42', 'Yes|found=Yes|id=42');
        Observer.Expect('tcomma', 'No|found=No|id=-777');
        Observer.Expect('tcomma_err', 'The value "4,2" can''t be evaluated into type Integer.|Evaluate:Format');
        Observer.Expect('texp', 'No|found=No|id=-777');
        Observer.Expect('texp_err', 'The value "1e3" can''t be evaluated into type Integer.|Evaluate:Format');
        Observer.Expect('tempty', 'No|found=No|id=-777');
        Observer.Expect('tempty_err', 'The value "" can''t be evaluated into type Integer.|Evaluate:Format');
        Observer.Expect('tzero_pad', 'Yes|found=Yes|id=42');
        Observer.Verify();
    end;

    [Test]
    procedure P142_IntKey_Limits()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
    begin
        Seed();
        Probe(Observer, 'max', '2147483647');
        Big := 2147483647;
        Big := Big + 1;
        Probe(Observer, 'max_plus_1', Format(Big));
        Big := 2147483647;
        Big := Big * 1000;
        Probe(Observer, 'max_times_1000', Format(Big));
        Big := -2147483647;
        Big := Big - 1;
        Probe(Observer, 'min', Format(Big));
        Big := Big - 1;
        Probe(Observer, 'min_minus_1', Format(Big));
        Probe(Observer, 'tdec', '42.0');
        Probe(Observer, 'tabc', 'abc');
        Probe(Observer, 'tmissing', '43');
        Probe(Observer, 'huge', '99999999999999999999999');
        Observer.Expect('max', 'Yes|found=Yes|id=2147483647');
        Observer.Expect('max_plus_1', 'No|found=No|id=-777');
        Observer.Expect('max_plus_1_err', 'Value was either too large or too small for an Int32.|AL:Overflow');
        Observer.Expect('max_times_1000', 'No|found=No|id=-777');
        Observer.Expect('max_times_1000_err', 'Value was either too large or too small for an Int32.|AL:Overflow');
        Observer.Expect('min', 'Yes|found=No|id=0');
        Observer.Expect('min_minus_1', 'No|found=No|id=-777');
        Observer.Expect('min_minus_1_err', 'Value was either too large or too small for an Int32.|AL:Overflow');
        Observer.Expect('tdec', 'No|found=No|id=-777');
        Observer.Expect('tdec_err', 'The value "42.0" can''t be evaluated into type Integer.|Evaluate:Format');
        Observer.Expect('tabc', 'No|found=No|id=-777');
        Observer.Expect('tabc_err', 'The value "abc" can''t be evaluated into type Integer.|Evaluate:Format');
        Observer.Expect('tmissing', 'Yes|found=No|id=0');
        Observer.Expect('huge', 'No|found=No|id=-777');
        Observer.Expect('huge_err', 'Value was either too large or too small for an Int32.|AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure P142_IntKey_ThousandSeparatorAndFormat()
    var
        Observer: Codeunit "Probe Observer";
        RRef: RecordRef;
        Found: Boolean;
        Got: Integer;
        Ok: Boolean;
        TextVar: Text;
    begin
        Seed();
        RRef.Open(Database::"LT P142 Int Key");
        RRef.FindFirst();
        Observer.Observe('first_format', Format(RRef.Field(1).Value));
        Probe(Observer, 'first_get', Format(RRef.Field(1).Value));
        RRef.Next();
        Probe(Observer, 'second_get', Format(RRef.Field(1).Value));
        RRef.FindLast();
        Observer.Observe('last_format', Format(RRef.Field(1).Value));
        Probe(Observer, 'last_get', Format(RRef.Field(1).Value));
        Probe(Observer, 'thousand', '1,000');
        Probe(Observer, 'thousand_plain', '1000');
        TextVar := '42';
        Ok := TryGet(TextVar, Found, Got);
        Observer.Observe('textvar', Format(Ok) + '|' + Format(Found) + '|' + Format(Got));
        Observer.Expect('first_format', '-1');
        Observer.Expect('first_get', 'Yes|found=Yes|id=-1');
        Observer.Expect('second_get', 'Yes|found=Yes|id=0');
        Observer.Expect('last_format', '2147483647');
        Observer.Expect('last_get', 'Yes|found=Yes|id=2147483647');
        Observer.Expect('thousand', 'No|found=No|id=-777');
        Observer.Expect('thousand_err', 'The value "1,000" can''t be evaluated into type Integer.|Evaluate:Format');
        Observer.Expect('thousand_plain', 'Yes|found=Yes|id=1000');
        Observer.Expect('textvar', 'Yes|Yes|42');
        Observer.Verify();
    end;
}
