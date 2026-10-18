codeunit 79913 "WC Evaluate PBT ErrorLevel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_PageBackgroundTaskErrorLevel()
    var
        V: PageBackgroundTaskErrorLevel;
        R: Boolean;
        Txt: Text;
    begin
        R := Evaluate(V, 'Warning');
        Txt += ' | ' + 'evaluate_Warning ' + Format(R) + ' value=' + Format(V);
        R := Evaluate(V, 'NoSuchLevel');
        Txt += ' | ' + 'evaluate_bad ' + Format(R) + ' value=' + Format(V);
        Error('OBSERVE:' + Txt);
    end;
}

