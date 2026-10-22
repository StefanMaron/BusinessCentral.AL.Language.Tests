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
        Observer.Expect('1033', 'globally_enabled=Yes stx_file_exist=Yes');
        Observer.Expect('1031', 'globally_enabled=Yes stx_file_exist=Yes');
        Observer.Expect('2057', 'globally_enabled=Yes stx_file_exist=Yes');
        Observer.Expect('1030', 'globally_enabled=Yes stx_file_exist=Yes');
        Observer.Expect('1036', 'globally_enabled=Yes stx_file_exist=Yes');
#if BC29PLUS
        Observer.Expect('globally enabled count', '212');
#else
        Observer.Expect('globally enabled count', '208');
#endif
#if BC29PLUS
        Observer.Expect('stx file exist count', '49');
#else
        Observer.Expect('stx file exist count', '48');
#endif
#if BC29PLUS
        Observer.Expect('both count', '49');
#else
        Observer.Expect('both count', '48');
#endif
        Observer.Expect('1033 with both findfirst', 'Yes');
        Observer.Expect('1031 with both findfirst', 'Yes');
        Observer.Verify();
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
        Observer.Expect('BGR', 'count=1 1026|Bulgarian (Bulgaria)|BGR|866|bg-BG');
        Observer.Expect('CHS', 'count=1 2052|Chinese (China)|CHS|936|zh-CN');
        Observer.Expect('CSY', 'count=1 1029|Czech (Czechia)|CSY|852|cs-CZ');
        Observer.Expect('DAN', 'count=1 1030|Danish (Denmark)|DAN|850|da-DK');
        Observer.Expect('DEA', 'count=1 3079|German (Austria)|DEA|850|de-AT');
        Observer.Expect('DES', 'count=1 2055|German (Switzerland)|DES|850|de-CH');
        Observer.Expect('DEU', 'count=1 1031|German (Germany)|DEU|850|de-DE');
        Observer.Expect('ENA', 'count=1 3081|English (Australia)|ENA|850|en-AU');
        Observer.Expect('ENC', 'count=1 4105|English (Canada)|ENC|850|en-CA');
        Observer.Expect('ENG', 'count=1 2057|English (United Kingdom)|ENG|850|en-GB');
        Observer.Expect('ENI', 'count=1 6153|English (Ireland)|ENI|850|en-IE');
        Observer.Expect('ENU', 'count=1 1033|English (United States)|ENU|437|en-US');
        Observer.Expect('ENZ', 'count=1 5129|English (New Zealand)|ENZ|850|en-NZ');
        Observer.Expect('ESM', 'count=1 2058|Spanish (Mexico)|ESM|850|es-MX');
        Observer.Expect('ENP', 'count=1 13321|English (Philippines)|ENP|437|en-PH');
        Observer.Expect('ESP', 'count=1 1034|Spanish (Spain, Sort Order=tradnl)|ESP|850|es-ES');
        Observer.Expect('ESN', 'count=1 3082|Spanish (Spain)|ESN|850|es-ES');
        Observer.Expect('ESO', 'count=1 9226|Spanish (Colombia)|ESO|850|es-CO');
        Observer.Verify();
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
        Observer.Expect('ESR', 'count=1 10250|Spanish (Peru)|ESR|850|es-PE');
        Observer.Expect('ESS', 'count=1 11274|Spanish (Argentina)|ESS|850|es-AR');
        Observer.Expect('ELL', 'count=1 1032|Greek (Greece)|ELL|737|el-GR');
        Observer.Expect('ETI', 'count=1 1061|Estonian (Estonia)|ETI|775|et-EE');
        Observer.Expect('FIN', 'count=1 1035|Finnish (Finland)|FIN|850|fi-FI');
        Observer.Expect('FRA', 'count=1 1036|French (France)|FRA|850|fr-FR');
        Observer.Expect('FRB', 'count=1 2060|French (Belgium)|FRB|850|fr-BE');
        Observer.Expect('FRC', 'count=1 3084|French (Canada)|FRC|850|fr-CA');
        Observer.Expect('FRS', 'count=1 4108|French (Switzerland)|FRS|850|fr-CH');
        Observer.Expect('HRV', 'count=1 1050|Croatian (Croatia)|HRV|852|hr-HR');
        Observer.Expect('HUN', 'count=1 1038|Hungarian (Hungary)|HUN|852|hu-HU');
        Observer.Expect('IND', 'count=1 1057|Indonesian (Indonesia)|IND|850|id-ID');
        Observer.Expect('ISL', 'count=1 1039|Icelandic (Iceland)|ISL|850|is-IS');
        Observer.Expect('ITA', 'count=1 1040|Italian (Italy)|ITA|850|it-IT');
        Observer.Expect('ITS', 'count=1 2064|Italian (Switzerland)|ITS|850|it-CH');
        Observer.Expect('JPN', 'count=1 1041|Japanese (Japan)|JPN|932|ja-JP');
        Observer.Expect('KOR', 'count=1 1042|Korean (South Korea)|KOR|949|ko-KR');
        Observer.Expect('LTH', 'count=1 1063|Lithuanian (Lithuania)|LTH|775|lt-LT');
        Observer.Verify();
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
        Observer.Expect('LVI', 'count=1 1062|Latvian (Latvia)|LVI|775|lv-LV');
        Observer.Expect('MSL', 'count=1 1086|Malay (Malaysia)|MSL|850|ms-MY');
        Observer.Expect('NLD', 'count=1 1043|Dutch (Netherlands)|NLD|850|nl-NL');
        Observer.Expect('NLB', 'count=1 2067|Dutch (Belgium)|NLB|850|nl-BE');
        Observer.Expect('NON', 'count=1 2068|Norwegian Nynorsk (Norway)|NON|850|nn-NO');
        Observer.Expect('NOR', 'count=1 1044|Norwegian Bokmål (Norway)|NOR|850|nb-NO');
        Observer.Expect('PLK', 'count=1 1045|Polish (Poland)|PLK|852|pl-PL');
        Observer.Expect('PTG', 'count=1 2070|Portuguese (Portugal)|PTG|850|pt-PT');
        Observer.Expect('PTB', 'count=1 1046|Portuguese (Brazil)|PTB|850|pt-BR');
        Observer.Expect('ROM', 'count=1 1048|Romanian (Romania)|ROM|852|ro-RO');
        Observer.Expect('RUS', 'count=1 1049|Russian (Russia)|RUS|866|ru-RU');
        Observer.Expect('SRP', 'count=1 11290|Serbian (Latin, Montenegro)|SRP|852|sr-Latn-ME');
        Observer.Expect('SKY', 'count=1 1051|Slovak (Slovakia)|SKY|852|sk-SK');
        Observer.Expect('SLV', 'count=1 1060|Slovenian (Slovenia)|SLV|852|sl-SI');
        Observer.Expect('SVE', 'count=1 1053|Swedish (Sweden)|SVE|850|sv-SE');
        Observer.Expect('THA', 'count=1 1054|Thai (Thailand)|THA|874|th-TH');
        Observer.Expect('TRK', 'count=1 1055|Turkish (Türkiye)|TRK|857|tr-TR');
        Observer.Expect('UKR', 'count=1 1058|Ukrainian (Ukraine)|UKR|866|uk-UA');
        Observer.Verify();
    end;
}
