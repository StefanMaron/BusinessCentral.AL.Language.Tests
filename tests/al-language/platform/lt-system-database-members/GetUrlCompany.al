// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73980
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetUrl company argument variants (blank, unknown, case, special chars, long)
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

codeunit 73980 "LT P95 GetUrl Company"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(Url: Text): Text
    begin
        exit(Format(Url <> '') + '|' + Format(Url.StartsWith('http')) + '|' + Format(Url.Contains('company=')) + '|' + Format(Url.Contains('page=')) + '|' + Format(Url.Contains('report=')) + '|' + Format(Url.Contains('codeunit=')) + '|' + Format(Url.Contains('table=')));
    end;

    local procedure Tail(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, '?');
        if P = 0 then
            exit('noquery');
        exit(CopyStr(Url, P));
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;


    [TryFunction]
    local procedure TryU(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Web, Cn);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; Cn: Text)
    var
        R: Text;
    begin
        if TryU(Cn, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure GetUrl_Company_Variants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'blank', ' ');
        One(Observer, 'nonexistent', 'No Such Company P95');
        One(Observer, 'lower_current', LowerCase(CompanyName()));
        One(Observer, 'upper_current', UpperCase(CompanyName()));
        One(Observer, 'ampersand', 'A&B');
        One(Observer, 'space_slash', 'A B/C');
        One(Observer, 'percent', '100%');
        One(Observer, 'unicode', 'Gesch' + 'ae' + 'ft Ü€');
        One(Observer, 'quote', 'It''s');
        One(Observer, 'hash_question', 'A#B?C');
        One(Observer, 'long', PadStr('', 120, 'x'));
        Observer.Finish();
    end;

}
