codeunit 79911 "WC Evaluate PageStyle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Evaluate_PageStyle()
    var
        V: PageStyle;
        R: Boolean;
        Txt: Text;
    begin
        R := Evaluate(V, 'Strong');
        Txt += ' | ' + 'evaluate_Strong ' + Format(R) + ' value=' + Format(V);
        R := Evaluate(V, 'NoSuchStyle');
        Txt += ' | ' + 'evaluate_bad ' + Format(R) + ' value=' + Format(V);
        Error('OBSERVE:' + Txt);
    end;
}

