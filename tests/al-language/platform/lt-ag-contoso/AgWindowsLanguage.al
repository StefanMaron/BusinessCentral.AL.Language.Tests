// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: every row of the system table Windows Language (2000000045) on a fresh tenant, in key order: the row count (208 on BC 27 and 28, 212 on BC 29), digests over the ids and over id, name,
// abbreviated name, code page and tag of all rows. The refused writes are in AgPlatformReadOnly.al.
// Facts: the full list behind the three or four rows other files pin (record/TestWindowsLanguageTable.al, errors/lt-ms-refusals-129, -133, -137).
// Writer QX (Microsoft's DemoTool): Globally Enabled and STX File Exist of a few rows and the counts they filter; the row the DemoTool's
//   lookup by Abbreviated Name finds for each of its 54 language codes (count of the filter and the row).
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

    // ---- Writer QX (Microsoft's DemoTool: Demo Data Setup relates to Windows Language where Globally Enabled and STX File Exist are true;
    // Create Language finds each language by SetCurrentKey("Abbreviated Name") + SetFilter("Abbreviated Name", Code) + FindFirst) ----

    local procedure QxFlags(var WindowsLanguage: Record "Windows Language"; Id: Integer): Text
    begin
        if not WindowsLanguage.Get(Id) then
            exit('no row');
        exit('globally_enabled=' + Format(WindowsLanguage."Globally Enabled") + ' stx_file_exist=' + Format(WindowsLanguage."STX File Exist"));
    end;

    [Test]
    procedure QX_WindowsLanguage_GloballyEnabledAndStxFileExist()
    var
        WindowsLanguage: Record "Windows Language";
    begin
        Observer.Observe('1033', QxFlags(WindowsLanguage, 1033));
        Observer.Observe('1031', QxFlags(WindowsLanguage, 1031));
        Observer.Observe('2057', QxFlags(WindowsLanguage, 2057));
        Observer.Observe('1030', QxFlags(WindowsLanguage, 1030));
        Observer.Observe('1036', QxFlags(WindowsLanguage, 1036));
        WindowsLanguage.Reset();
        WindowsLanguage.SetRange("Globally Enabled", true);
        Observer.Observe('globally enabled count', Format(WindowsLanguage.Count()));
        WindowsLanguage.Reset();
        WindowsLanguage.SetRange("STX File Exist", true);
        Observer.Observe('stx file exist count', Format(WindowsLanguage.Count()));
        WindowsLanguage.SetRange("Globally Enabled", true);
        Observer.Observe('both count', Format(WindowsLanguage.Count()));
        WindowsLanguage.SetRange("Language ID", 1033);
        Observer.Observe('1033 with both findfirst', Format(WindowsLanguage.FindFirst()));
        WindowsLanguage.SetRange("Language ID", 1031);
        Observer.Observe('1031 with both findfirst', Format(WindowsLanguage.FindFirst()));
        Observer.Finish();
    end;

    local procedure QxByAbbreviation(Code: Text): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetCurrentKey("Abbreviated Name");
        WindowsLanguage.SetFilter("Abbreviated Name", Code);
        if not WindowsLanguage.FindFirst() then
            exit('count=' + Format(WindowsLanguage.Count()) + ' none');
        exit('count=' + Format(WindowsLanguage.Count()) + ' ' + RowText(WindowsLanguage));
    end;

    [Test]
    procedure QX_WindowsLanguage_ByAbbreviatedName_Part1()
    begin
        Observer.Observe('BGR', QxByAbbreviation('BGR'));
        Observer.Observe('CHS', QxByAbbreviation('CHS'));
        Observer.Observe('CSY', QxByAbbreviation('CSY'));
        Observer.Observe('DAN', QxByAbbreviation('DAN'));
        Observer.Observe('DEA', QxByAbbreviation('DEA'));
        Observer.Observe('DES', QxByAbbreviation('DES'));
        Observer.Observe('DEU', QxByAbbreviation('DEU'));
        Observer.Observe('ENA', QxByAbbreviation('ENA'));
        Observer.Observe('ENC', QxByAbbreviation('ENC'));
        Observer.Observe('ENG', QxByAbbreviation('ENG'));
        Observer.Observe('ENI', QxByAbbreviation('ENI'));
        Observer.Observe('ENU', QxByAbbreviation('ENU'));
        Observer.Observe('ENZ', QxByAbbreviation('ENZ'));
        Observer.Observe('ESM', QxByAbbreviation('ESM'));
        Observer.Observe('ENP', QxByAbbreviation('ENP'));
        Observer.Observe('ESP', QxByAbbreviation('ESP'));
        Observer.Observe('ESN', QxByAbbreviation('ESN'));
        Observer.Observe('ESO', QxByAbbreviation('ESO'));
        Observer.Finish();
    end;

    [Test]
    procedure QX_WindowsLanguage_ByAbbreviatedName_Part2()
    begin
        Observer.Observe('ESR', QxByAbbreviation('ESR'));
        Observer.Observe('ESS', QxByAbbreviation('ESS'));
        Observer.Observe('ELL', QxByAbbreviation('ELL'));
        Observer.Observe('ETI', QxByAbbreviation('ETI'));
        Observer.Observe('FIN', QxByAbbreviation('FIN'));
        Observer.Observe('FRA', QxByAbbreviation('FRA'));
        Observer.Observe('FRB', QxByAbbreviation('FRB'));
        Observer.Observe('FRC', QxByAbbreviation('FRC'));
        Observer.Observe('FRS', QxByAbbreviation('FRS'));
        Observer.Observe('HRV', QxByAbbreviation('HRV'));
        Observer.Observe('HUN', QxByAbbreviation('HUN'));
        Observer.Observe('IND', QxByAbbreviation('IND'));
        Observer.Observe('ISL', QxByAbbreviation('ISL'));
        Observer.Observe('ITA', QxByAbbreviation('ITA'));
        Observer.Observe('ITS', QxByAbbreviation('ITS'));
        Observer.Observe('JPN', QxByAbbreviation('JPN'));
        Observer.Observe('KOR', QxByAbbreviation('KOR'));
        Observer.Observe('LTH', QxByAbbreviation('LTH'));
        Observer.Finish();
    end;

    [Test]
    procedure QX_WindowsLanguage_ByAbbreviatedName_Part3()
    begin
        Observer.Observe('LVI', QxByAbbreviation('LVI'));
        Observer.Observe('MSL', QxByAbbreviation('MSL'));
        Observer.Observe('NLD', QxByAbbreviation('NLD'));
        Observer.Observe('NLB', QxByAbbreviation('NLB'));
        Observer.Observe('NON', QxByAbbreviation('NON'));
        Observer.Observe('NOR', QxByAbbreviation('NOR'));
        Observer.Observe('PLK', QxByAbbreviation('PLK'));
        Observer.Observe('PTG', QxByAbbreviation('PTG'));
        Observer.Observe('PTB', QxByAbbreviation('PTB'));
        Observer.Observe('ROM', QxByAbbreviation('ROM'));
        Observer.Observe('RUS', QxByAbbreviation('RUS'));
        Observer.Observe('SRP', QxByAbbreviation('SRP'));
        Observer.Observe('SKY', QxByAbbreviation('SKY'));
        Observer.Observe('SLV', QxByAbbreviation('SLV'));
        Observer.Observe('SVE', QxByAbbreviation('SVE'));
        Observer.Observe('THA', QxByAbbreviation('THA'));
        Observer.Observe('TRK', QxByAbbreviation('TRK'));
        Observer.Observe('UKR', QxByAbbreviation('UKR'));
        Observer.Finish();
    end;
}
