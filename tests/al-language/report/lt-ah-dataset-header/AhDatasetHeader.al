// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own report 78602, codeunit 78603; LT QK Setup Rows (86940)
// Probe: the CompanyAddressLine1..8 elements of the report dataset header (SaveAs Xml, BC 29 and later) for several fillings of the
// Company Information address fields (Address, Address 2, City, Post Code, County, Country/Region Code). Only line 1 (= Name) was pinned before
// (corpus issue 636, item 3). The test restores the Company Information row it changed. Header_AddressLines_AsInCorpusDatabase writes its
// own row through codeunit 86940 "LT QK Setup Rows" (writer QK, 2026-10-21); the name is kept so the corpus case id stays.
// BC versions: 29+ (BC 27 and 28 write no company block in the header)

#if BC29PLUS
report 78602 "LT AH Header Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './AhDatasetHeaderLayout.rdl';
            Caption = 'LT AH layout';
        }
    }
}

codeunit 78603 "LT AH Dataset Header"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddressLines(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        Tag: Text;
        Index: Integer;
    begin
        TempBlob.CreateOutStream(OutStr);
        if not Report.SaveAs(Report::"LT AH Header Report", '', ReportFormat::Xml, OutStr) then
            exit('SaveAs returned false');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            for Index := 1 to 8 do begin
                Tag := 'CompanyAddressLine' + Format(Index);
                if Line.StartsWith('<' + Tag + '>') then
                    Result += Format(Index) + '=[' + Line.Substring(StrLen(Tag) + 3, StrLen(Line) - 2 * StrLen(Tag) - 5) + '] '
                else
                    if Line = '<' + Tag + ' />' then
                        Result += Format(Index) + '=[] ';
            end;
        end;
        exit(Result);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Address: Text; Address2: Text; City: Text; PostCode: Text; County: Text; CountryCode: Code[10])
    var
        Info: Record "Company Information";
        Saved: Record "Company Information";
    begin
        Info.Get();
        Saved := Info;
        Info.Address := CopyStr(Address, 1, MaxStrLen(Info.Address));
        Info."Address 2" := CopyStr(Address2, 1, MaxStrLen(Info."Address 2"));
        Info.City := CopyStr(City, 1, MaxStrLen(Info.City));
        Info."Post Code" := CopyStr(PostCode, 1, MaxStrLen(Info."Post Code"));
        Info.County := CopyStr(County, 1, MaxStrLen(Info.County));
        Info."Country/Region Code" := CountryCode;
        Info.Modify();
        Observer.Observe(Name, AddressLines());
        Info.Get();
        Info.TransferFields(Saved, false);
        Info.Modify();
    end;

    [Test]
    procedure Header_AddressLines_AsInCorpusDatabase()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
        Info: Record "Company Information";
    begin
        // Writer QK (owner 2026-10-21): the test writes its own Company Information row (QkSetupRows.al) instead of reading the demo row.
        QkRows.WriteCompanyInformation();
        Info.Get();
        Observer.Observe('db', Info.Name + '|' + Info.Address + '|' + Info."Address 2" + '|' + Info.City + '|' + Info."Post Code" + '|' + Info.County + '|' + Info."Country/Region Code");
        Observer.Observe('as_is', AddressLines());
        QkRows.RestoreCompanyInformation();
        Observer.Expect('db', 'LT QK Company|QK Street 1|QK Floor 2|QK Town|QK-1234||LTQK');
        Observer.Expect('as_is', '1=[LT QK Company] 2=[QK Street 1] 3=[QK Floor 2] 4=[QK Town, QK-1234] 5=[LT QK Land] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure Header_AddressLines_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Country: Record "Country/Region";
    begin
        if not Country.Get('AHX') then begin
            Country.Init();
            Country.Code := 'AHX';
            Country.Name := 'Ahland';
            Country.Insert();
        end;
        Run(Observer, 'all_filled_no_county', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', '', '');
        Run(Observer, 'all_filled_county', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', 'Countyshire', '');
        Run(Observer, 'country_code_only', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', '', 'AHX');
        Run(Observer, 'all_five_filled', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', 'Countyshire', 'AHX');
        Run(Observer, 'no_address2', 'Street 1', '', 'Town', 'ZIP 12', 'Countyshire', 'AHX');
        Observer.Expect('all_filled_no_county', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[ZIP 12 Town] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('all_filled_county', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[ZIP 12 Town] 5=[Countyshire] 6=[] 7=[] 8=[] ');
        Observer.Expect('country_code_only', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[Town, ZIP 12] 5=[Ahland] 6=[] 7=[] 8=[] ');
        Observer.Expect('all_five_filled', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[Town, ZIP 12] 5=[Countyshire] 6=[Ahland] 7=[] 8=[] ');
        Observer.Expect('no_address2', '1=[<Company>] 2=[Street 1] 3=[Town, ZIP 12] 4=[Countyshire] 5=[Ahland] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure Header_AddressLines_PartlyFilled()
    var
        Observer: Codeunit "Probe Observer";
        Country: Record "Country/Region";
    begin
        if not Country.Get('AHX') then begin
            Country.Init();
            Country.Code := 'AHX';
            Country.Name := 'Ahland';
            Country.Insert();
        end;
        Run(Observer, 'only_city', '', '', 'Town', '', '', '');
        Run(Observer, 'only_post_code', '', '', '', 'ZIP 12', '', '');
        Run(Observer, 'only_county', '', '', '', '', 'Countyshire', '');
        Run(Observer, 'only_country', '', '', '', '', '', 'AHX');
        Run(Observer, 'all_empty', '', '', '', '', '', '');
        Country.Get('AHX');
        Country.Delete();
        Observer.Expect('only_city', '1=[<Company>] 2=[Town] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('only_post_code', '1=[<Company>] 2=[ZIP 12 ] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('only_county', '1=[<Company>] 2=[Countyshire] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('only_country', '1=[<Company>] 2=[Ahland] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('all_empty', '1=[<Company>] 2=[] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5681): the CompanyLogo element of the header for a Company Information row without a Picture, with the
    // reporter's 1x1 PNG, and with bytes that are no image. The raw line is read; Picture is written through Base64 Convert.FromBase64.
    local procedure QvLogoLine(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        if not Report.SaveAs(Report::"LT AH Header Report", '', ReportFormat::Xml, OutStr) then
            exit('SaveAs returned false');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Contains('CompanyLogo') then
                Result += Line.Trim() + '|';
        end;
        exit(Result);
    end;

    local procedure QvLogoNode(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Document: XmlDocument;
        Node: XmlNode;
    begin
        TempBlob.CreateOutStream(OutStr);
        if not Report.SaveAs(Report::"LT AH Header Report", '', ReportFormat::Xml, OutStr) then
            exit('SaveAs returned false');
        TempBlob.CreateInStream(InStr);
        if not XmlDocument.ReadFrom(InStr, Document) then
            exit('not XML');
        if not Document.SelectSingleNode('/ReportDataSet/BCReportInformation/CompanyMetadata/CompanyLogo', Node) then
            exit('no CompanyLogo element');
        exit('[' + Node.AsXmlElement().InnerText() + ']');
    end;

    local procedure QvSetPicture(Base64Text: Text; PlainText: Text)
    var
        Info: Record "Company Information";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        Info.Get();
        Clear(Info.Picture);
        if (Base64Text <> '') or (PlainText <> '') then begin
            Info.Picture.CreateOutStream(OutS);
            if Base64Text <> '' then
                Base64.FromBase64(Base64Text, OutS)
            else
                OutS.WriteText(PlainText);
        end;
        Info.Modify();
    end;

    [Test]
    procedure QV_Header_CompanyLogo_PictureVariants()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
        Base64: Codeunit "Base64 Convert";
        PngTxt: Text;
    begin
        PngTxt := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        QkRows.WriteCompanyInformation();
        QvSetPicture('', '');
        Observer.Observe('no picture line', QvLogoLine());
        Observer.Observe('no picture node', QvLogoNode());
        QvSetPicture(PngTxt, '');
        Observer.Observe('png line', QvLogoLine());
        Observer.Observe('png node equals input', Format(QvLogoNode() = '[' + PngTxt + ']'));
        QvSetPicture('', 'not an image');
        Observer.Observe('text bytes node', QvLogoNode());
        Observer.Observe('text bytes base64', Base64.ToBase64('not an image'));
        QkRows.RestoreCompanyInformation();
        Observer.Finish();
    end;
}
#endif
