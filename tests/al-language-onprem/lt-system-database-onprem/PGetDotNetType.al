// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope (OnPrem app only: System.GetDotNetType (DotNet))
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61236
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: dotnet declarations of System.String and System.Type (mscorlib), aliases LTP109Str2 and LTP109Typ2
//
// GetDotNetType of a Text, Integer, Boolean, Decimal, Code and an assigned DotNet variable: the type's FullName.
// BC versions: 29 (27 and 28 by CI)
dotnet
{
    assembly("mscorlib")
    {
        type("System.String"; "LTP109Str2") { }
        type("System.Type"; "LTP109Typ2") { }
    }
}

codeunit 61236 "LT P109 GetDotNetType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFullName(Value: Variant; var Name: Text)
    var
        T: DotNet LTP109Typ2;
    begin
        T := GetDotNetType(Value);
        Name := T.FullName;
    end;

    local procedure Outcome(Value: Variant): Text
    var
        Name: Text;
    begin
        if TryFullName(Value, Name) then
            exit(Name);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_GetDotNetType_Simple()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Cd: Code[10];
        Int: Integer;
        Big: BigInteger;
        Dec: Decimal;
        Bool: Boolean;
        Dt: Date;
        Tm: Time;
        Gd: Guid;
    begin
        Txt := 'abc';
        Cd := 'ABC';
        Int := 1;
        Big := 2;
        Dec := 3.5;
        Bool := true;
        Dt := DMY2Date(1, 1, 2020);
        Tm := 120000T;
        Observer.Observe('text', Outcome(Txt));
        Observer.Observe('code', Outcome(Cd));
        Observer.Observe('integer', Outcome(Int));
        Observer.Observe('biginteger', Outcome(Big));
        Observer.Observe('decimal', Outcome(Dec));
        Observer.Observe('boolean', Outcome(Bool));
        Observer.Observe('date', Outcome(Dt));
        Observer.Observe('time', Outcome(Tm));
        Observer.Observe('guid', Outcome(Gd));
        Observer.Expect('text', 'System.String');
        Observer.Expect('code', 'System.String');
        Observer.Expect('integer', 'System.Int32');
        Observer.Expect('biginteger', 'System.Decimal');
        Observer.Expect('decimal', 'System.Decimal');
        Observer.Expect('boolean', 'System.Boolean');
        Observer.Expect('date', 'System.DateTime');
        Observer.Expect('time', 'System.DateTime');
        Observer.Expect('guid', 'System.Guid');
        Observer.Verify();
    end;

    [Test]
    procedure P109_GetDotNetType_DotNetValue()
    var
        Observer: Codeunit "Probe Observer";
        Str: DotNet LTP109Str2;
    begin
        Str := Str.Copy('abc');
        Observer.Observe('dotnet_string', Outcome(Str));
        Observer.Expect('dotnet_string', 'System.String');
        Observer.Verify();
    end;
}
