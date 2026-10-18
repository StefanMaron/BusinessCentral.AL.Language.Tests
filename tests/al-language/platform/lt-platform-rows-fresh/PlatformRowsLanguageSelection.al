// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: the count and every row, in 18 tests of 12 rows each,, with every column, of the platform table Language Selection on the fresh tenant of a test container (read through RecordRef by table name).
// First rows of the platform tables are also pinned in platform/lt-platform-tables/PtCloudTables.al. Object id 78100.

codeunit 78100 "LT AD Plat Rows Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TableIdByName(TableName: Text): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object Name", TableName);
        if AllObj.FindFirst() then
            exit(AllObj."Object ID");
        exit(-1);
    end;

    local procedure RowText(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Class() = FieldClass::Normal then
                if FR.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Result += FR.Name() + '=<' + Format(FR.Type()) + '>|'
                else
                    Result += FR.Name() + '=' + Format(FR.Value()) + '|';
        end;
        exit(Result);
    end;

    local procedure Dump(var Observer: Codeunit "Probe Observer"; TableName: Text; Skip: Integer; Take: Integer)
    var
        RR: RecordRef;
        Id: Integer;
        n: Integer;
    begin
        Id := TableIdByName(TableName);
        Observer.Observe(TableName + ' id', Format(Id));
        if Id < 0 then
            exit;
        RR.Open(Id);
                if RR.FindSet() then
            repeat
                n += 1;
                if (n > Skip) and (n <= Skip + Take) then
                    Observer.Observe(TableName + ' row ' + Format(n), RowText(RR));
            until (RR.Next() = 0) or (n >= Skip + Take);
    end;

    [Test]
    procedure Rows_LanguageSelection_01()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 0, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 1', 'Name=Afrikaans (South Africa)|Language Tag=af-ZA|Language ID=1078|Primary Language ID=1078|Abbreviated Name=AFK|Enabled=No|');
        Observer.Expect('Language Selection row 2', 'Name=Albanian (Albania)|Language Tag=sq-AL|Language ID=1052|Primary Language ID=1052|Abbreviated Name=SQI|Enabled=No|');
        Observer.Expect('Language Selection row 3', 'Name=Amharic (Ethiopia)|Language Tag=am-ET|Language ID=1118|Primary Language ID=1118|Abbreviated Name=AMH|Enabled=No|');
        Observer.Expect('Language Selection row 4', 'Name=Arabic (Algeria)|Language Tag=ar-DZ|Language ID=5121|Primary Language ID=1025|Abbreviated Name=ARG|Enabled=No|');
        Observer.Expect('Language Selection row 5', 'Name=Arabic (Bahrain)|Language Tag=ar-BH|Language ID=15361|Primary Language ID=1025|Abbreviated Name=ARH|Enabled=No|');
        Observer.Expect('Language Selection row 6', 'Name=Arabic (Egypt)|Language Tag=ar-EG|Language ID=3073|Primary Language ID=1025|Abbreviated Name=ARE|Enabled=No|');
        Observer.Expect('Language Selection row 7', 'Name=Arabic (Iraq)|Language Tag=ar-IQ|Language ID=2049|Primary Language ID=1025|Abbreviated Name=ARI|Enabled=No|');
        Observer.Expect('Language Selection row 8', 'Name=Arabic (Jordan)|Language Tag=ar-JO|Language ID=11265|Primary Language ID=1025|Abbreviated Name=ARJ|Enabled=No|');
        Observer.Expect('Language Selection row 9', 'Name=Arabic (Kuwait)|Language Tag=ar-KW|Language ID=13313|Primary Language ID=1025|Abbreviated Name=ARK|Enabled=No|');
        Observer.Expect('Language Selection row 10', 'Name=Arabic (Lebanon)|Language Tag=ar-LB|Language ID=12289|Primary Language ID=1025|Abbreviated Name=ARB|Enabled=No|');
        Observer.Expect('Language Selection row 11', 'Name=Arabic (Libya)|Language Tag=ar-LY|Language ID=4097|Primary Language ID=1025|Abbreviated Name=ARL|Enabled=No|');
        Observer.Expect('Language Selection row 12', 'Name=Arabic (Morocco)|Language Tag=ar-MA|Language ID=6145|Primary Language ID=1025|Abbreviated Name=ARM|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_02()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 12, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 13', 'Name=Arabic (Oman)|Language Tag=ar-OM|Language ID=8193|Primary Language ID=1025|Abbreviated Name=ARO|Enabled=No|');
        Observer.Expect('Language Selection row 14', 'Name=Arabic (Qatar)|Language Tag=ar-QA|Language ID=16385|Primary Language ID=1025|Abbreviated Name=ARQ|Enabled=No|');
        Observer.Expect('Language Selection row 15', 'Name=Arabic (Saudi Arabia)|Language Tag=ar-SA|Language ID=1025|Primary Language ID=1025|Abbreviated Name=ARA|Enabled=No|');
        Observer.Expect('Language Selection row 16', 'Name=Arabic (Syria)|Language Tag=ar-SY|Language ID=10241|Primary Language ID=1025|Abbreviated Name=ARS|Enabled=No|');
        Observer.Expect('Language Selection row 17', 'Name=Arabic (Tunisia)|Language Tag=ar-TN|Language ID=7169|Primary Language ID=1025|Abbreviated Name=ART|Enabled=No|');
        Observer.Expect('Language Selection row 18', 'Name=Arabic (United Arab Emirates)|Language Tag=ar-AE|Language ID=14337|Primary Language ID=1025|Abbreviated Name=ARU|Enabled=No|');
        Observer.Expect('Language Selection row 19', 'Name=Arabic (Yemen)|Language Tag=ar-YE|Language ID=9217|Primary Language ID=1025|Abbreviated Name=ARY|Enabled=No|');
        Observer.Expect('Language Selection row 20', 'Name=Armenian (Armenia)|Language Tag=hy-AM|Language ID=1067|Primary Language ID=1067|Abbreviated Name=HYE|Enabled=No|');
        Observer.Expect('Language Selection row 21', 'Name=Assamese (India)|Language Tag=as-IN|Language ID=1101|Primary Language ID=1101|Abbreviated Name=ASM|Enabled=No|');
        Observer.Expect('Language Selection row 22', 'Name=Azerbaijani (Cyrillic, Azerbaijan)|Language Tag=az-Cyrl-AZ|Language ID=2092|Primary Language ID=1068|Abbreviated Name=AZC|Enabled=No|');
        Observer.Expect('Language Selection row 23', 'Name=Azerbaijani (Latin, Azerbaijan)|Language Tag=az-Latn-AZ|Language ID=1068|Primary Language ID=1068|Abbreviated Name=AZE|Enabled=No|');
        Observer.Expect('Language Selection row 24', 'Name=Bangla (Bangladesh)|Language Tag=bn-BD|Language ID=2117|Primary Language ID=1093|Abbreviated Name=BNB|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 24, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_03b()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 30, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_04()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 36, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 37', 'Name=Croatian (Bosnia & Herzegovina)|Language Tag=hr-BA|Language ID=4122|Primary Language ID=1050|Abbreviated Name=HRB|Enabled=No|');
        Observer.Expect('Language Selection row 38', 'Name=Croatian (Croatia)|Language Tag=hr-HR|Language ID=1050|Primary Language ID=1050|Abbreviated Name=HRV|Enabled=Yes|');
        Observer.Expect('Language Selection row 39', 'Name=Czech (Czechia)|Language Tag=cs-CZ|Language ID=1029|Primary Language ID=1029|Abbreviated Name=CSY|Enabled=Yes|');
        Observer.Expect('Language Selection row 40', 'Name=Danish (Denmark)|Language Tag=da-DK|Language ID=1030|Primary Language ID=1030|Abbreviated Name=DAN|Enabled=Yes|');
        Observer.Expect('Language Selection row 41', 'Name=Dutch (Belgium)|Language Tag=nl-BE|Language ID=2067|Primary Language ID=1043|Abbreviated Name=NLB|Enabled=Yes|');
        Observer.Expect('Language Selection row 42', 'Name=Dutch (Netherlands)|Language Tag=nl-NL|Language ID=1043|Primary Language ID=1043|Abbreviated Name=NLD|Enabled=Yes|');
        Observer.Expect('Language Selection row 43', 'Name=English (Australia)|Language Tag=en-AU|Language ID=3081|Primary Language ID=1033|Abbreviated Name=ENA|Enabled=Yes|');
        Observer.Expect('Language Selection row 44', 'Name=English (Belize)|Language Tag=en-BZ|Language ID=10249|Primary Language ID=1033|Abbreviated Name=ENL|Enabled=No|');
        Observer.Expect('Language Selection row 45', 'Name=English (Canada)|Language Tag=en-CA|Language ID=4105|Primary Language ID=1033|Abbreviated Name=ENC|Enabled=Yes|');
        Observer.Expect('Language Selection row 46', 'Name=English (Hong Kong SAR China)|Language Tag=en-HK|Language ID=15369|Primary Language ID=1033|Abbreviated Name=ENH|Enabled=No|');
        Observer.Expect('Language Selection row 47', 'Name=English (India)|Language Tag=en-IN|Language ID=16393|Primary Language ID=1033|Abbreviated Name=ENN|Enabled=No|');
        Observer.Expect('Language Selection row 48', 'Name=English (Indonesia)|Language Tag=en-ID|Language ID=14345|Primary Language ID=1033|Abbreviated Name=ZZZ|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_05()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 48, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 49', 'Name=English (Ireland)|Language Tag=en-IE|Language ID=6153|Primary Language ID=1033|Abbreviated Name=ENI|Enabled=No|');
        Observer.Expect('Language Selection row 50', 'Name=English (Jamaica)|Language Tag=en-JM|Language ID=8201|Primary Language ID=1033|Abbreviated Name=ENJ|Enabled=No|');
        Observer.Expect('Language Selection row 51', 'Name=English (Malaysia)|Language Tag=en-MY|Language ID=17417|Primary Language ID=1033|Abbreviated Name=ENM|Enabled=No|');
        Observer.Expect('Language Selection row 52', 'Name=English (New Zealand)|Language Tag=en-NZ|Language ID=5129|Primary Language ID=1033|Abbreviated Name=ENZ|Enabled=Yes|');
        Observer.Expect('Language Selection row 53', 'Name=English (Philippines)|Language Tag=en-PH|Language ID=13321|Primary Language ID=1033|Abbreviated Name=ENP|Enabled=No|');
        Observer.Expect('Language Selection row 54', 'Name=English (Singapore)|Language Tag=en-SG|Language ID=18441|Primary Language ID=1033|Abbreviated Name=ENE|Enabled=No|');
        Observer.Expect('Language Selection row 55', 'Name=English (South Africa)|Language Tag=en-ZA|Language ID=7177|Primary Language ID=1033|Abbreviated Name=ENS|Enabled=Yes|');
        Observer.Expect('Language Selection row 56', 'Name=English (Trinidad & Tobago)|Language Tag=en-TT|Language ID=11273|Primary Language ID=1033|Abbreviated Name=ENT|Enabled=No|');
        Observer.Expect('Language Selection row 57', 'Name=English (United Kingdom)|Language Tag=en-GB|Language ID=2057|Primary Language ID=1033|Abbreviated Name=ENG|Enabled=Yes|');
        Observer.Expect('Language Selection row 58', 'Name=English (United States)|Language Tag=en-US|Language ID=1033|Primary Language ID=1033|Abbreviated Name=ENU|Enabled=Yes|');
        Observer.Expect('Language Selection row 59', 'Name=English (Zimbabwe)|Language Tag=en-ZW|Language ID=12297|Primary Language ID=1033|Abbreviated Name=ENW|Enabled=No|');
        Observer.Expect('Language Selection row 60', 'Name=Estonian (Estonia)|Language Tag=et-EE|Language ID=1061|Primary Language ID=1061|Abbreviated Name=ETI|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_06()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 60, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 61', 'Name=Faroese (Faroe Islands)|Language Tag=fo-FO|Language ID=1080|Primary Language ID=1080|Abbreviated Name=FOS|Enabled=No|');
        Observer.Expect('Language Selection row 62', 'Name=Filipino (Philippines)|Language Tag=fil-PH|Language ID=1124|Primary Language ID=1124|Abbreviated Name=FPO|Enabled=No|');
        Observer.Expect('Language Selection row 63', 'Name=Finnish (Finland)|Language Tag=fi-FI|Language ID=1035|Primary Language ID=1035|Abbreviated Name=FIN|Enabled=Yes|');
        Observer.Expect('Language Selection row 64', 'Name=French (Belgium)|Language Tag=fr-BE|Language ID=2060|Primary Language ID=1036|Abbreviated Name=FRB|Enabled=Yes|');
        Observer.Expect('Language Selection row 65', 'Name=French (Cameroon)|Language Tag=fr-CM|Language ID=11276|Primary Language ID=1036|Abbreviated Name=FRE|Enabled=No|');
        Observer.Expect('Language Selection row 66', 'Name=French (Canada)|Language Tag=fr-CA|Language ID=3084|Primary Language ID=1036|Abbreviated Name=FRC|Enabled=Yes|');
        Observer.Expect('Language Selection row 67', 'Name=French (Congo - Kinshasa)|Language Tag=fr-CD|Language ID=9228|Primary Language ID=1036|Abbreviated Name=FRD|Enabled=No|');
        Observer.Expect('Language Selection row 68', 'Name=French (Côte d’Ivoire)|Language Tag=fr-CI|Language ID=12300|Primary Language ID=1036|Abbreviated Name=FRI|Enabled=No|');
        Observer.Expect('Language Selection row 69', 'Name=French (France)|Language Tag=fr-FR|Language ID=1036|Primary Language ID=1036|Abbreviated Name=FRA|Enabled=Yes|');
        Observer.Expect('Language Selection row 70', 'Name=French (Haiti)|Language Tag=fr-HT|Language ID=15372|Primary Language ID=1036|Abbreviated Name=FRH|Enabled=No|');
        Observer.Expect('Language Selection row 71', 'Name=French (Luxembourg)|Language Tag=fr-LU|Language ID=5132|Primary Language ID=1036|Abbreviated Name=FRL|Enabled=No|');
        Observer.Expect('Language Selection row 72', 'Name=French (Mali)|Language Tag=fr-ML|Language ID=13324|Primary Language ID=1036|Abbreviated Name=FRF|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_07()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 72, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 73', 'Name=French (Monaco)|Language Tag=fr-MC|Language ID=6156|Primary Language ID=1036|Abbreviated Name=FRM|Enabled=No|');
        Observer.Expect('Language Selection row 74', 'Name=French (Morocco)|Language Tag=fr-MA|Language ID=14348|Primary Language ID=1036|Abbreviated Name=FRO|Enabled=No|');
        Observer.Expect('Language Selection row 75', 'Name=French (Réunion)|Language Tag=fr-RE|Language ID=8204|Primary Language ID=1036|Abbreviated Name=FRR|Enabled=No|');
        Observer.Expect('Language Selection row 76', 'Name=French (Senegal)|Language Tag=fr-SN|Language ID=10252|Primary Language ID=1036|Abbreviated Name=FRN|Enabled=No|');
        Observer.Expect('Language Selection row 77', 'Name=French (Switzerland)|Language Tag=fr-CH|Language ID=4108|Primary Language ID=1036|Abbreviated Name=FRS|Enabled=Yes|');
        Observer.Expect('Language Selection row 78', 'Name=Fula (Latin, Senegal)|Language Tag=ff-Latn-SN|Language ID=2151|Primary Language ID=1127|Abbreviated Name=FUL|Enabled=No|');
        Observer.Expect('Language Selection row 79', 'Name=Fula (Nigeria)|Language Tag=ff-NG|Language ID=1127|Primary Language ID=1127|Abbreviated Name=ZZZ|Enabled=No|');
        Observer.Expect('Language Selection row 80', 'Name=Galician (Spain)|Language Tag=gl-ES|Language ID=1110|Primary Language ID=1110|Abbreviated Name=GLC|Enabled=No|');
        Observer.Expect('Language Selection row 81', 'Name=Georgian (Georgia)|Language Tag=ka-GE|Language ID=1079|Primary Language ID=1079|Abbreviated Name=KAT|Enabled=No|');
        Observer.Expect('Language Selection row 82', 'Name=German (Austria)|Language Tag=de-AT|Language ID=3079|Primary Language ID=1031|Abbreviated Name=DEA|Enabled=Yes|');
        Observer.Expect('Language Selection row 83', 'Name=German (Germany)|Language Tag=de-DE|Language ID=1031|Primary Language ID=1031|Abbreviated Name=DEU|Enabled=Yes|');
        Observer.Expect('Language Selection row 84', 'Name=German (Liechtenstein)|Language Tag=de-LI|Language ID=5127|Primary Language ID=1031|Abbreviated Name=DEC|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_08()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 84, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 85', 'Name=German (Luxembourg)|Language Tag=de-LU|Language ID=4103|Primary Language ID=1031|Abbreviated Name=DEL|Enabled=No|');
        Observer.Expect('Language Selection row 86', 'Name=German (Switzerland)|Language Tag=de-CH|Language ID=2055|Primary Language ID=1031|Abbreviated Name=DES|Enabled=Yes|');
        Observer.Expect('Language Selection row 87', 'Name=Greek (Greece)|Language Tag=el-GR|Language ID=1032|Primary Language ID=1032|Abbreviated Name=ELL|Enabled=Yes|');
        Observer.Expect('Language Selection row 88', 'Name=Gujarati (India)|Language Tag=gu-IN|Language ID=1095|Primary Language ID=1095|Abbreviated Name=GUJ|Enabled=No|');
        Observer.Expect('Language Selection row 89', 'Name=Hawaiian (United States)|Language Tag=haw-US|Language ID=1141|Primary Language ID=1141|Abbreviated Name=HAW|Enabled=No|');
        Observer.Expect('Language Selection row 90', 'Name=Hebrew (Israel)|Language Tag=he-IL|Language ID=1037|Primary Language ID=1037|Abbreviated Name=HEB|Enabled=No|');
        Observer.Expect('Language Selection row 91', 'Name=Hindi (India)|Language Tag=hi-IN|Language ID=1081|Primary Language ID=1081|Abbreviated Name=HIN|Enabled=No|');
        Observer.Expect('Language Selection row 92', 'Name=Hungarian (Hungary)|Language Tag=hu-HU|Language ID=1038|Primary Language ID=1038|Abbreviated Name=HUN|Enabled=Yes|');
        Observer.Expect('Language Selection row 93', 'Name=Icelandic (Iceland)|Language Tag=is-IS|Language ID=1039|Primary Language ID=1039|Abbreviated Name=ISL|Enabled=Yes|');
        Observer.Expect('Language Selection row 94', 'Name=Igbo (Nigeria)|Language Tag=ig-NG|Language ID=1136|Primary Language ID=1136|Abbreviated Name=IBO|Enabled=No|');
        Observer.Expect('Language Selection row 95', 'Name=Inari Sami (Finland)|Language Tag=smn-FI|Language ID=9275|Primary Language ID=1083|Abbreviated Name=SMN|Enabled=No|');
        Observer.Expect('Language Selection row 96', 'Name=Indonesian (Indonesia)|Language Tag=id-ID|Language ID=1057|Primary Language ID=1057|Abbreviated Name=IND|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_09()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 96, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 97', 'Name=Irish (Ireland)|Language Tag=ga-IE|Language ID=2108|Primary Language ID=1084|Abbreviated Name=IRE|Enabled=No|');
        Observer.Expect('Language Selection row 98', 'Name=Italian (Italy)|Language Tag=it-IT|Language ID=1040|Primary Language ID=1040|Abbreviated Name=ITA|Enabled=Yes|');
        Observer.Expect('Language Selection row 99', 'Name=Italian (Switzerland)|Language Tag=it-CH|Language ID=2064|Primary Language ID=1040|Abbreviated Name=ITS|Enabled=Yes|');
        Observer.Expect('Language Selection row 100', 'Name=Japanese (Japan)|Language Tag=ja-JP|Language ID=1041|Primary Language ID=1041|Abbreviated Name=JPN|Enabled=Yes|');
        Observer.Expect('Language Selection row 101', 'Name=Kalaallisut (Greenland)|Language Tag=kl-GL|Language ID=1135|Primary Language ID=1135|Abbreviated Name=KAL|Enabled=No|');
        Observer.Expect('Language Selection row 102', 'Name=Kannada (India)|Language Tag=kn-IN|Language ID=1099|Primary Language ID=1099|Abbreviated Name=KDI|Enabled=No|');
        Observer.Expect('Language Selection row 103', 'Name=Kazakh (Kazakhstan)|Language Tag=kk-KZ|Language ID=1087|Primary Language ID=1087|Abbreviated Name=KKZ|Enabled=No|');
        Observer.Expect('Language Selection row 104', 'Name=Khmer (Cambodia)|Language Tag=km-KH|Language ID=1107|Primary Language ID=1107|Abbreviated Name=KHM|Enabled=No|');
        Observer.Expect('Language Selection row 105', 'Name=Kinyarwanda (Rwanda)|Language Tag=rw-RW|Language ID=1159|Primary Language ID=1159|Abbreviated Name=KIN|Enabled=No|');
        Observer.Expect('Language Selection row 106', 'Name=Konkani (India)|Language Tag=kok-IN|Language ID=1111|Primary Language ID=1111|Abbreviated Name=KNK|Enabled=No|');
        Observer.Expect('Language Selection row 107', 'Name=Korean (South Korea)|Language Tag=ko-KR|Language ID=1042|Primary Language ID=1042|Abbreviated Name=KOR|Enabled=Yes|');
        Observer.Expect('Language Selection row 108', 'Name=Kyrgyz (Kyrgyzstan)|Language Tag=ky-KG|Language ID=1088|Primary Language ID=1088|Abbreviated Name=KYR|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 108, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 109', 'Name=Lao (Laos)|Language Tag=lo-LA|Language ID=1108|Primary Language ID=1108|Abbreviated Name=LAO|Enabled=No|');
        Observer.Expect('Language Selection row 110', 'Name=Latvian (Latvia)|Language Tag=lv-LV|Language ID=1062|Primary Language ID=1062|Abbreviated Name=LVI|Enabled=Yes|');
        Observer.Expect('Language Selection row 111', 'Name=Lithuanian (Lithuania)|Language Tag=lt-LT|Language ID=1063|Primary Language ID=1063|Abbreviated Name=LTH|Enabled=Yes|');
        Observer.Expect('Language Selection row 112', 'Name=Lower Sorbian (Germany)|Language Tag=dsb-DE|Language ID=2094|Primary Language ID=1070|Abbreviated Name=DSB|Enabled=No|');
        Observer.Expect('Language Selection row 113', 'Name=Luxembourgish (Luxembourg)|Language Tag=lb-LU|Language ID=1134|Primary Language ID=1134|Abbreviated Name=LBX|Enabled=No|');
        Observer.Expect('Language Selection row 114', 'Name=Macedonian (North Macedonia)|Language Tag=mk-MK|Language ID=1071|Primary Language ID=1071|Abbreviated Name=MKI|Enabled=No|');
        Observer.Expect('Language Selection row 115', 'Name=Malay (Brunei)|Language Tag=ms-BN|Language ID=2110|Primary Language ID=1086|Abbreviated Name=MSB|Enabled=No|');
        Observer.Expect('Language Selection row 116', 'Name=Malay (Malaysia)|Language Tag=ms-MY|Language ID=1086|Primary Language ID=1086|Abbreviated Name=MSL|Enabled=No|');
        Observer.Expect('Language Selection row 117', 'Name=Malayalam (India)|Language Tag=ml-IN|Language ID=1100|Primary Language ID=1100|Abbreviated Name=MYM|Enabled=No|');
        Observer.Expect('Language Selection row 118', 'Name=Maltese (Malta)|Language Tag=mt-MT|Language ID=1082|Primary Language ID=1082|Abbreviated Name=MLT|Enabled=No|');
        Observer.Expect('Language Selection row 119', 'Name=Māori (New Zealand)|Language Tag=mi-NZ|Language ID=1153|Primary Language ID=1153|Abbreviated Name=MRI|Enabled=No|');
        Observer.Expect('Language Selection row 120', 'Name=Marathi (India)|Language Tag=mr-IN|Language ID=1102|Primary Language ID=1102|Abbreviated Name=MAR|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_11()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 120, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 121', 'Name=Mongolian (Mongolia)|Language Tag=mn-MN|Language ID=1104|Primary Language ID=1104|Abbreviated Name=MNN|Enabled=No|');
        Observer.Expect('Language Selection row 122', 'Name=Nepali (India)|Language Tag=ne-IN|Language ID=2145|Primary Language ID=1121|Abbreviated Name=NEI|Enabled=No|');
        Observer.Expect('Language Selection row 123', 'Name=Nepali (Nepal)|Language Tag=ne-NP|Language ID=1121|Primary Language ID=1121|Abbreviated Name=NEP|Enabled=No|');
        Observer.Expect('Language Selection row 124', 'Name=Northern Sami (Finland)|Language Tag=se-FI|Language ID=3131|Primary Language ID=1083|Abbreviated Name=SMG|Enabled=No|');
        Observer.Expect('Language Selection row 125', 'Name=Northern Sami (Norway)|Language Tag=se-NO|Language ID=1083|Primary Language ID=1083|Abbreviated Name=SME|Enabled=No|');
        Observer.Expect('Language Selection row 126', 'Name=Northern Sami (Sweden)|Language Tag=se-SE|Language ID=2107|Primary Language ID=1083|Abbreviated Name=SMF|Enabled=No|');
        Observer.Expect('Language Selection row 127', 'Name=Norwegian Bokmål (Norway)|Language Tag=nb-NO|Language ID=1044|Primary Language ID=1044|Abbreviated Name=NOR|Enabled=Yes|');
        Observer.Expect('Language Selection row 128', 'Name=Norwegian Nynorsk (Norway)|Language Tag=nn-NO|Language ID=2068|Primary Language ID=1044|Abbreviated Name=NON|Enabled=No|');
        Observer.Expect('Language Selection row 129', 'Name=Occitan (France)|Language Tag=oc-FR|Language ID=1154|Primary Language ID=1154|Abbreviated Name=OCI|Enabled=No|');
        Observer.Expect('Language Selection row 130', 'Name=Odia (India)|Language Tag=or-IN|Language ID=1096|Primary Language ID=1096|Abbreviated Name=ORI|Enabled=No|');
        Observer.Expect('Language Selection row 131', 'Name=Oromo (Ethiopia)|Language Tag=om-ET|Language ID=1138|Primary Language ID=1138|Abbreviated Name=ORM|Enabled=No|');
        Observer.Expect('Language Selection row 132', 'Name=Pashto (Afghanistan)|Language Tag=ps-AF|Language ID=1123|Primary Language ID=1123|Abbreviated Name=PAS|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_12()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 132, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 133', 'Name=Persian (Iran)|Language Tag=fa-IR|Language ID=1065|Primary Language ID=1065|Abbreviated Name=FAR|Enabled=No|');
        Observer.Expect('Language Selection row 134', 'Name=Polish (Poland)|Language Tag=pl-PL|Language ID=1045|Primary Language ID=1045|Abbreviated Name=PLK|Enabled=Yes|');
        Observer.Expect('Language Selection row 135', 'Name=Portuguese (Brazil)|Language Tag=pt-BR|Language ID=1046|Primary Language ID=1046|Abbreviated Name=PTB|Enabled=Yes|');
        Observer.Expect('Language Selection row 136', 'Name=Portuguese (Portugal)|Language Tag=pt-PT|Language ID=2070|Primary Language ID=1046|Abbreviated Name=PTG|Enabled=Yes|');
        Observer.Expect('Language Selection row 137', 'Name=Punjabi (Arabic, Pakistan)|Language Tag=pa-Arab-PK|Language ID=2118|Primary Language ID=1094|Abbreviated Name=PAP|Enabled=No|');
        Observer.Expect('Language Selection row 138', 'Name=Punjabi (India)|Language Tag=pa-IN|Language ID=1094|Primary Language ID=1094|Abbreviated Name=PAN|Enabled=No|');
        Observer.Expect('Language Selection row 139', 'Name=Romanian (Moldova)|Language Tag=ro-MD|Language ID=2072|Primary Language ID=1048|Abbreviated Name=ROD|Enabled=No|');
        Observer.Expect('Language Selection row 140', 'Name=Romanian (Romania)|Language Tag=ro-RO|Language ID=1048|Primary Language ID=1048|Abbreviated Name=ROM|Enabled=Yes|');
        Observer.Expect('Language Selection row 141', 'Name=Romansh (Switzerland)|Language Tag=rm-CH|Language ID=1047|Primary Language ID=1047|Abbreviated Name=RMC|Enabled=No|');
        Observer.Expect('Language Selection row 142', 'Name=Russian (Moldova)|Language Tag=ru-MD|Language ID=2073|Primary Language ID=1049|Abbreviated Name=RUM|Enabled=No|');
        Observer.Expect('Language Selection row 143', 'Name=Russian (Russia)|Language Tag=ru-RU|Language ID=1049|Primary Language ID=1049|Abbreviated Name=RUS|Enabled=Yes|');
        Observer.Expect('Language Selection row 144', 'Name=Sanskrit (India)|Language Tag=sa-IN|Language ID=1103|Primary Language ID=1103|Abbreviated Name=SAN|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_13()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 144, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_13b()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 150, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_14()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 156, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 157', 'Name=Slovak (Slovakia)|Language Tag=sk-SK|Language ID=1051|Primary Language ID=1051|Abbreviated Name=SKY|Enabled=Yes|');
        Observer.Expect('Language Selection row 158', 'Name=Slovenian (Slovenia)|Language Tag=sl-SI|Language ID=1060|Primary Language ID=1060|Abbreviated Name=SLV|Enabled=Yes|');
        Observer.Expect('Language Selection row 159', 'Name=Somali (Somalia)|Language Tag=so-SO|Language ID=1143|Primary Language ID=1143|Abbreviated Name=SOM|Enabled=No|');
        Observer.Expect('Language Selection row 160', 'Name=Spanish (Argentina)|Language Tag=es-AR|Language ID=11274|Primary Language ID=1034|Abbreviated Name=ESS|Enabled=No|');
        Observer.Expect('Language Selection row 161', 'Name=Spanish (Bolivia)|Language Tag=es-BO|Language ID=16394|Primary Language ID=1034|Abbreviated Name=ESB|Enabled=No|');
        Observer.Expect('Language Selection row 162', 'Name=Spanish (Chile)|Language Tag=es-CL|Language ID=13322|Primary Language ID=1034|Abbreviated Name=ESL|Enabled=No|');
        Observer.Expect('Language Selection row 163', 'Name=Spanish (Colombia)|Language Tag=es-CO|Language ID=9226|Primary Language ID=1034|Abbreviated Name=ESO|Enabled=No|');
        Observer.Expect('Language Selection row 164', 'Name=Spanish (Costa Rica)|Language Tag=es-CR|Language ID=5130|Primary Language ID=1034|Abbreviated Name=ESC|Enabled=No|');
        Observer.Expect('Language Selection row 165', 'Name=Spanish (Cuba)|Language Tag=es-CU|Language ID=23562|Primary Language ID=1034|Abbreviated Name=ESK|Enabled=No|');
        Observer.Expect('Language Selection row 166', 'Name=Spanish (Dominican Republic)|Language Tag=es-DO|Language ID=7178|Primary Language ID=1034|Abbreviated Name=ESD|Enabled=No|');
        Observer.Expect('Language Selection row 167', 'Name=Spanish (Ecuador)|Language Tag=es-EC|Language ID=12298|Primary Language ID=1034|Abbreviated Name=ESF|Enabled=No|');
        Observer.Expect('Language Selection row 168', 'Name=Spanish (El Salvador)|Language Tag=es-SV|Language ID=17418|Primary Language ID=1034|Abbreviated Name=ESE|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 168, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_15b()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 174, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_LanguageSelection_16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 180, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 181', 'Name=Spanish (Uruguay)|Language Tag=es-UY|Language ID=14346|Primary Language ID=1034|Abbreviated Name=ESY|Enabled=No|');
        Observer.Expect('Language Selection row 182', 'Name=Spanish (Venezuela)|Language Tag=es-VE|Language ID=8202|Primary Language ID=1034|Abbreviated Name=ESV|Enabled=No|');
        Observer.Expect('Language Selection row 183', 'Name=Swahili (Kenya)|Language Tag=sw-KE|Language ID=1089|Primary Language ID=1089|Abbreviated Name=SWK|Enabled=No|');
        Observer.Expect('Language Selection row 184', 'Name=Swedish (Finland)|Language Tag=sv-FI|Language ID=2077|Primary Language ID=1053|Abbreviated Name=SVF|Enabled=No|');
        Observer.Expect('Language Selection row 185', 'Name=Swedish (Sweden)|Language Tag=sv-SE|Language ID=1053|Primary Language ID=1053|Abbreviated Name=SVE|Enabled=Yes|');
        Observer.Expect('Language Selection row 186', 'Name=Swiss German (France)|Language Tag=gsw-FR|Language ID=1156|Primary Language ID=1156|Abbreviated Name=GSW|Enabled=No|');
        Observer.Expect('Language Selection row 187', 'Name=Syriac (Syria)|Language Tag=syr-SY|Language ID=1114|Primary Language ID=1114|Abbreviated Name=SYR|Enabled=No|');
        Observer.Expect('Language Selection row 188', 'Name=Tamil (India)|Language Tag=ta-IN|Language ID=1097|Primary Language ID=1097|Abbreviated Name=TAI|Enabled=No|');
        Observer.Expect('Language Selection row 189', 'Name=Tamil (Sri Lanka)|Language Tag=ta-LK|Language ID=2121|Primary Language ID=1097|Abbreviated Name=TAM|Enabled=No|');
        Observer.Expect('Language Selection row 190', 'Name=Tatar (Russia)|Language Tag=tt-RU|Language ID=1092|Primary Language ID=1092|Abbreviated Name=TTT|Enabled=No|');
        Observer.Expect('Language Selection row 191', 'Name=Telugu (India)|Language Tag=te-IN|Language ID=1098|Primary Language ID=1098|Abbreviated Name=TEL|Enabled=No|');
        Observer.Expect('Language Selection row 192', 'Name=Thai (Thailand)|Language Tag=th-TH|Language ID=1054|Primary Language ID=1054|Abbreviated Name=THA|Enabled=Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_17()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 192, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 193', 'Name=Tibetan (China)|Language Tag=bo-CN|Language ID=1105|Primary Language ID=1105|Abbreviated Name=BOB|Enabled=No|');
        Observer.Expect('Language Selection row 194', 'Name=Tigrinya (Eritrea)|Language Tag=ti-ER|Language ID=2163|Primary Language ID=1139|Abbreviated Name=TIR|Enabled=No|');
        Observer.Expect('Language Selection row 195', 'Name=Tigrinya (Ethiopia)|Language Tag=ti-ET|Language ID=1139|Primary Language ID=1139|Abbreviated Name=TIE|Enabled=No|');
        Observer.Expect('Language Selection row 196', 'Name=Turkish (Türkiye)|Language Tag=tr-TR|Language ID=1055|Primary Language ID=1055|Abbreviated Name=TRK|Enabled=Yes|');
        Observer.Expect('Language Selection row 197', 'Name=Turkmen (Turkmenistan)|Language Tag=tk-TM|Language ID=1090|Primary Language ID=1090|Abbreviated Name=TUK|Enabled=No|');
        Observer.Expect('Language Selection row 198', 'Name=Ukrainian (Ukraine)|Language Tag=uk-UA|Language ID=1058|Primary Language ID=1058|Abbreviated Name=UKR|Enabled=Yes|');
        Observer.Expect('Language Selection row 199', 'Name=Upper Sorbian (Germany)|Language Tag=hsb-DE|Language ID=1070|Primary Language ID=1070|Abbreviated Name=HSB|Enabled=No|');
        Observer.Expect('Language Selection row 200', 'Name=Urdu (India)|Language Tag=ur-IN|Language ID=2080|Primary Language ID=1056|Abbreviated Name=URI|Enabled=No|');
        Observer.Expect('Language Selection row 201', 'Name=Urdu (Pakistan)|Language Tag=ur-PK|Language ID=1056|Primary Language ID=1056|Abbreviated Name=URD|Enabled=No|');
        Observer.Expect('Language Selection row 202', 'Name=Uyghur (China)|Language Tag=ug-CN|Language ID=1152|Primary Language ID=1152|Abbreviated Name=UIG|Enabled=No|');
        Observer.Expect('Language Selection row 203', 'Name=Uzbek (Cyrillic, Uzbekistan)|Language Tag=uz-Cyrl-UZ|Language ID=2115|Primary Language ID=1091|Abbreviated Name=UZC|Enabled=No|');
        Observer.Expect('Language Selection row 204', 'Name=Uzbek (Latin, Uzbekistan)|Language Tag=uz-Latn-UZ|Language ID=1091|Primary Language ID=1091|Abbreviated Name=UZB|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_LanguageSelection_18()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'Language Selection', 204, 12);
        Observer.Expect('Language Selection id', '2000000050');
        Observer.Expect('Language Selection row 205', 'Name=Vietnamese (Vietnam)|Language Tag=vi-VN|Language ID=1066|Primary Language ID=1066|Abbreviated Name=VIT|Enabled=Yes|');
        Observer.Expect('Language Selection row 206', 'Name=Welsh (United Kingdom)|Language Tag=cy-GB|Language ID=1106|Primary Language ID=1106|Abbreviated Name=CYM|Enabled=No|');
        Observer.Expect('Language Selection row 207', 'Name=Western Frisian (Netherlands)|Language Tag=fy-NL|Language ID=1122|Primary Language ID=1122|Abbreviated Name=FYN|Enabled=No|');
        Observer.Expect('Language Selection row 208', 'Name=Wolof (Senegal)|Language Tag=wo-SN|Language ID=1160|Primary Language ID=1160|Abbreviated Name=WOL|Enabled=No|');
        Observer.Expect('Language Selection row 209', 'Name=Xhosa (South Africa)|Language Tag=xh-ZA|Language ID=1076|Primary Language ID=1076|Abbreviated Name=XHO|Enabled=No|');
        Observer.Expect('Language Selection row 210', 'Name=Yakut (Russia)|Language Tag=sah-RU|Language ID=1157|Primary Language ID=1157|Abbreviated Name=SAH|Enabled=No|');
        Observer.Expect('Language Selection row 211', 'Name=Yoruba (Nigeria)|Language Tag=yo-NG|Language ID=1130|Primary Language ID=1130|Abbreviated Name=YOR|Enabled=No|');
        Observer.Expect('Language Selection row 212', 'Name=Zulu (South Africa)|Language Tag=zu-ZA|Language ID=1077|Primary Language ID=1077|Abbreviated Name=ZUL|Enabled=No|');
        Observer.Verify();
    end;

    [Test]
    procedure Count_LanguageSelection()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Id: Integer;
    begin
        Id := TableIdByName('Language Selection');
        Observer.Observe('id', Format(Id));
        RR.Open(Id);
        Observer.Observe('count', Format(RR.Count()));
        Observer.Expect('id', '2000000050');
        Observer.Expect('count', '212');
        Observer.Verify();
    end;
}
