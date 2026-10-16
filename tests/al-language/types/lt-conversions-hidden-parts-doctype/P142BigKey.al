// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74542 "LT P142 Big Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; BigInteger) { }
        field(2; Info; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74544 "LT P142 Big Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Mid(): BigInteger
    var
        B: BigInteger;
    begin
        B := 2147483647;
        exit(B + 1);
    end;

    local procedure Seed()
    var
        R: Record "LT P142 Big Key";
        Ids: List of [BigInteger];
        I: BigInteger;
    begin
        R.DeleteAll();
        Ids.Add(0);
        Ids.Add(42);
        Ids.Add(-1);
        Ids.Add(4);
        Ids.Add(1000);
        Ids.Add(2147483647);
        Ids.Add(Mid());
        foreach I in Ids do begin
            Clear(R);
            R.Id := I;
            R.Info := 'row' + Format(I);
            R.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryGet(T: Text; var Found: Boolean; var Got: BigInteger)
    var
        R: Record "LT P142 Big Key";
    begin
        Found := R.Get(T);
        Got := R.Id;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; T: Text)
    var
        Found: Boolean;
        Got: BigInteger;
        Ok: Boolean;
    begin
        Got := -777;
        Ok := TryGet(T, Found, Got);
        Observer.Observe(Name, Format(Ok) + '|found=' + Format(Found) + '|id=' + Format(Got));
        if not Ok then
            Observer.Observe(Name + '_err', CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
    end;
}
