codeunit 79912 "WC Evaluate HttpRequestType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_HttpRequestType()
    var
        V: HttpRequestType;
        R: Boolean;
        Txt: Text;
    begin
        R := Evaluate(V, 'Get');
        Txt += ' | ' + 'evaluate_Get ' + Format(R) + ' value=' + Format(V);
        R := Evaluate(V, 'NoSuchType');
        Txt += ' | ' + 'evaluate_bad ' + Format(R) + ' value=' + Format(V);
        Error('OBSERVE:' + Txt);
    end;
}

