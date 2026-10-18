// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: every row of the system table Windows Language (2000000045) on a fresh tenant, in key order: the row count (208 on BC 27 and 28, 212 on BC 29), digests over the ids and over id, name,
// abbreviated name, code page and tag of all rows. The refused writes are in AgPlatformReadOnly.al.
// Facts: the full list behind the three or four rows other files pin (record/TestWindowsLanguageTable.al, errors/lt-ms-refusals-129, -133, -137).
// BC versions: 27-29

codeunit 78400 "LT AG Win Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Hash(Value: Text; var State: BigInteger)
    var
        Ch: Char;
        I: Integer;
        Code: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            Ch := Value[I];
            Code := Ch;
            State := (State * 31 + Code) mod 2147483629;
        end;
    end;

    local procedure RowText(var WindowsLanguage: Record "Windows Language"): Text
    begin
        exit(Format(WindowsLanguage."Language ID") + '|' + WindowsLanguage.Name + '|' + WindowsLanguage."Abbreviated Name" + '|' + WindowsLanguage."Primary CodePage" + '|' + WindowsLanguage."Language Tag");
    end;

    [Test]
    procedure WindowsLanguage_AllRows_CountAndDigest()
    var
        WindowsLanguage: Record "Windows Language";
        Dump: Text;
        IdDigest: BigInteger;
        RowDigest: BigInteger;
        Index: Integer;
    begin
        Observer.Observe('count', Format(WindowsLanguage.Count()));
        if WindowsLanguage.FindSet() then
            repeat
                Index += 1;
                Hash(Format(WindowsLanguage."Language ID") + ',', IdDigest);
                Hash(RowText(WindowsLanguage) + ';', RowDigest);
                if Index = 1 then
                    Dump := RowText(WindowsLanguage);
            until WindowsLanguage.Next() = 0;
        Observer.Observe('iterated', Format(Index));
        Observer.Observe('id_digest', Format(IdDigest));
        Observer.Observe('row_digest', Format(RowDigest));
        Observer.Observe('first', Dump);
        Observer.Observe('has_1028', Format(WindowsLanguage.Get(1028)));
#if BC29PLUS
        Observer.Expect('count', '212');
        Observer.Expect('iterated', '212');
        Observer.Expect('id_digest', '479874481');
        Observer.Expect('row_digest', '2094992348');
        Observer.Expect('first', '1025|Arabic (Saudi Arabia)|ARA|720|ar-SA');
        Observer.Expect('has_1028', 'Yes');
#else
        Observer.Expect('count', '208');
        Observer.Expect('iterated', '208');
        Observer.Expect('id_digest', '1152079226');
        Observer.Expect('row_digest', '1438204915');
        Observer.Expect('first', '1025|Arabic (Saudi Arabia)|ARA|720|ar-SA');
        Observer.Expect('has_1028', 'No');
#endif
        Observer.Verify();
    end;
}
