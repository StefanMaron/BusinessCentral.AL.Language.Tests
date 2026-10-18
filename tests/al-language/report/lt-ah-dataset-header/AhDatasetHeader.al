// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own report 78602, codeunit 78603
// Probe: the CompanyAddressLine1..8 elements of the report dataset header (SaveAs Xml, BC 29 and later) for several fillings of the
// Company Information address fields (Address, Address 2, City, Post Code, County, Country/Region Code). Only line 1 (= Name) was pinned before
// (corpus issue 636, item 3). The test restores the Company Information row it changed.
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
        Info: Record "Company Information";
    begin
        Info.Get();
        Observer.Observe('db', Info.Name + '|' + Info.Address + '|' + Info."Address 2" + '|' + Info.City + '|' + Info."Post Code" + '|' + Info.County + '|' + Info."Country/Region Code");
        Observer.Observe('as_is', AddressLines());
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
#endif
