// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70926, report 70922, reportextension 70923, codeunit 70924
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Report.WordXmlPart(Id, true) and (Id, false) of a report with an added column and an added nested data item
// BC versions: 29 (27 and 28 by CI)

table 70926 "LT P170 Wxp Ext Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Extra; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

report 70922 "LT P170 Wxp Ext Base"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT P170 Wxp Ext Row")
        {
            column(RowNo; "No.") { }
            column(RowName; Name) { }
        }
    }
}

reportextension 70923 "LT P170 Wxp Ext Add" extends "LT P170 Wxp Ext Base"
{
    dataset
    {
        add(Rows)
        {
            column(RowExtra; Extra) { }
        }
    }
}

codeunit 70924 "LT P170 Wxp Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Chunks(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        i: Integer;
    begin
        Observer.Observe(Name + '_len', Format(StrLen(Value)));
        for i := 0 to 7 do
            if StrLen(Value) > i * 700 then
                Observer.Observe(Name + '_' + Format(i), CopyStr(Value, i * 700 + 1, 700));
    end;

    [Test]
    procedure P170_WordXmlPart_Extension_FlagTrue()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Xml := Report.WordXmlPart(Report::"LT P170 Wxp Ext Base", true);
        Chunks(Observer, 'ext_true', Xml);
        Observer.Observe('has_extra', Format(Xml.Contains('RowExtra')));
        Observer.Expect('ext_true_len', '4627');
        Observer.Expect('ext_true_1', 'ext</AboutThisReportText>\r\n      <ReportHelpLink>Report Help Link</ReportHelpLink>\r\n    </ReportMetadata>\r\n    <ReportRequest>\r\n      <TenantEntraId>x</TenantEntraId>\r\n      <EnvironmentName>x</EnvironmentName>\r\n      <EnvironmentType>x</EnvironmentType>\r\n      <CompanyName>x</CompanyName>\r\n      <CompanyDisplayName>x</CompanyDisplayName>\r\n      <CompanyId>x</CompanyId>\r\n      <UserName>x</UserName>\r\n      <DateAndTime>x</DateAndTime>\r\n      <Language>Language</Language>\r\n      <FormatRegion>Format Region</FormatRegion>\r\n      <DateTimeValues>\r\n        <Year>x</Year>\r\n        <MonthNumbe');
        Observer.Expect('ext_true_2', 'r>Month Number</MonthNumber>\r\n        <DayNumber>x</DayNumber>\r\n        <Hour>x</Hour>\r\n        <Minute>x</Minute>\r\n      </DateTimeValues>\r\n    </ReportRequest>\r\n    <CompanyMetadata>\r\n      <CompanyName>x</CompanyName>\r\n      <CompanyDisplayName>x</CompanyDisplayName>\r\n      <CompanyAddressLines>\r\n        <CompanyAddressLine1>Company Address Line 1</CompanyAddressLine1>\r\n        <CompanyAddressLine2>Company Address Line 2</CompanyAddressLine2>\r\n        <CompanyAddressLine3>Company Address Line 3</CompanyAddressLine3>\r\n        <CompanyAddressLine4>Company Address Line 4</CompanyAddressLine4>\r\n        <CompanyAddressLine5>Company Address Line 5<');
        Observer.Expect('ext_true_3', '/CompanyAddressLine5>\r\n        <CompanyAddressLine6>Company Address Line 6</CompanyAddressLine6>\r\n        <CompanyAddressLine7>Company Address Line 7</CompanyAddressLine7>\r\n        <CompanyAddressLine8>Company Address Line 8</CompanyAddressLine8>\r\n      </CompanyAddressLines>\r\n      <CompanyPhone>Company Phone</CompanyPhone>\r\n      <CompanyPhoneCaption>Company Phone Caption</CompanyPhoneCaption>\r\n      <CompanyFaxNo>Company Fax No.</CompanyFaxNo>\r\n      <CompanyFaxNoCaption>Company Fax No. Caption</CompanyFaxNoCaption>\r\n      <CompanyEmail>Company Email</CompanyEmail>\r\n      <CompanyEmailCaption>Company Email Caption</CompanyEmailCaption>\r\n      <CompanyHomePage>Company Home Page</CompanyHom');
        Observer.Expect('ext_true_4', 'ePage>\r\n      <CompanyHomePageCaption>Company Home Page Caption</CompanyHomePageCaption>\r\n      <CompanyLogo>Company Logo</CompanyLogo>\r\n      <CompanyVATRegistrationNo>Company VAT Registration No.</CompanyVATRegistrationNo>\r\n      <CompanyVATRegistrationNoCaption>Company VAT Registration No. Caption</CompanyVATRegistrationNoCaption>\r\n      <CompanyRegistrationNo>Company Registration No.</CompanyRegistrationNo>\r\n      <CompanyRegistrationNoCaption>Company Registration No. Caption</CompanyRegistrationNoCaption>\r\n      <CompanyBankName>Company Bank Name</CompanyBankName>\r\n      <CompanyBankNameCaption>Company Bank Name Caption</CompanyBankNameCaption>\r\n      <CompanyBankAccountNo>Company Bank ');
        Observer.Expect('ext_true_5', 'Account No.</CompanyBankAccountNo>\r\n      <CompanyBankAccountNoCaption>Company Bank Account No. Caption</CompanyBankAccountNoCaption>\r\n      <CompanyBankBranchNo>Company Bank Branch No.</CompanyBankBranchNo>\r\n      <CompanyBankBranchNoCaption>Company Bank Branch No. Caption</CompanyBankBranchNoCaption>\r\n      <CompanyIBAN>Company IBAN</CompanyIBAN>\r\n      <CompanyIBANCaption>Company IBAN Caption</CompanyIBANCaption>\r\n      <CompanyBankSWIFT>Company Bank SWIFT</CompanyBankSWIFT>\r\n      <CompanyBankSWIFTCaption>Company Bank SWIFT Caption</CompanyBankSWIFTCaption>\r\n      <CompanyGiroNo>Company Giro No.</CompanyGiroNo>\r\n      <CompanyGiroNoCaption>Company Giro No. Caption</CompanyGiroNoCaption>\r');
        Observer.Expect('ext_true_6', '\n    </CompanyMetadata>\r\n  </BCReportInformation>\r\n  <Tooltips />\r\n  <Rows ElementType="DataItem" ElementId="578941028">\r\n    <RowExtra ElementType="Column" ElementId="499263731" DataType="Text">RowExtra</RowExtra>\r\n    <RowName ElementType="Column" ElementId="1179968888" DataType="Text">RowName</RowName>\r\n    <RowNo ElementType="Column" ElementId="104128374" DataType="Code">RowNo</RowNo>\r\n  </Rows>\r\n</NavWordReportXmlPart>');
        Observer.Expect('has_extra', 'Yes');
        Observer.Ignore('ext_true_0'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure P170_WordXmlPart_Extension_FlagFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Chunks(Observer, 'ext_false', Report.WordXmlPart(Report::"LT P170 Wxp Ext Base", false));
        Observer.Expect('ext_false_len', '4358');
        Observer.Expect('ext_false_1', '   <ReportHelpLink>Report Help Link</ReportHelpLink>\r\n    </ReportMetadata>\r\n    <ReportRequest>\r\n      <TenantEntraId>x</TenantEntraId>\r\n      <EnvironmentName>x</EnvironmentName>\r\n      <EnvironmentType>x</EnvironmentType>\r\n      <CompanyName>x</CompanyName>\r\n      <CompanyDisplayName>x</CompanyDisplayName>\r\n      <CompanyId>x</CompanyId>\r\n      <UserName>x</UserName>\r\n      <DateAndTime>x</DateAndTime>\r\n      <Language>Language</Language>\r\n      <FormatRegion>Format Region</FormatRegion>\r\n      <DateTimeValues>\r\n        <Year>x</Year>\r\n        <MonthNumber>x</MonthNumber>\r\n');
        Observer.Expect('ext_false_2', '        <DayNumber>x</DayNumber>\r\n        <Hour>x</Hour>\r\n        <Minute>x</Minute>\r\n      </DateTimeValues>\r\n    </ReportRequest>\r\n    <CompanyMetadata>\r\n      <CompanyName>x</CompanyName>\r\n      <CompanyDisplayName>x</CompanyDisplayName>\r\n      <CompanyAddressLines>\r\n        <CompanyAddressLine1>Company Address Line 1</CompanyAddressLine1>\r\n        <CompanyAddressLine2>Company Address Line 2</CompanyAddressLine2>\r\n        <CompanyAddressLine3>Company Address Line 3</CompanyAddressLine3>\r\n        <CompanyAddressLine4>Company Address Line 4</CompanyAddressLine4>\r\n        <CompanyAddressLine5>Company Address Line 5</CompanyAddressLine5>\r\n       ');
        Observer.Expect('ext_false_3', ' <CompanyAddressLine6>Company Address Line 6</CompanyAddressLine6>\r\n        <CompanyAddressLine7>Company Address Line 7</CompanyAddressLine7>\r\n        <CompanyAddressLine8>Company Address Line 8</CompanyAddressLine8>\r\n      </CompanyAddressLines>\r\n      <CompanyPhone>Company Phone</CompanyPhone>\r\n      <CompanyPhoneCaption>Company Phone Caption</CompanyPhoneCaption>\r\n      <CompanyFaxNo>Company Fax No.</CompanyFaxNo>\r\n      <CompanyFaxNoCaption>Company Fax No. Caption</CompanyFaxNoCaption>\r\n      <CompanyEmail>Company Email</CompanyEmail>\r\n      <CompanyEmailCaption>Company Email Caption</CompanyEmailCaption>\r\n      <CompanyHomePage>Company Home Page</CompanyHomePage>\r\n      <CompanyHomePage');
        Observer.Expect('ext_false_4', 'Caption>Company Home Page Caption</CompanyHomePageCaption>\r\n      <CompanyLogo>Company Logo</CompanyLogo>\r\n      <CompanyVATRegistrationNo>Company VAT Registration No.</CompanyVATRegistrationNo>\r\n      <CompanyVATRegistrationNoCaption>Company VAT Registration No. Caption</CompanyVATRegistrationNoCaption>\r\n      <CompanyRegistrationNo>Company Registration No.</CompanyRegistrationNo>\r\n      <CompanyRegistrationNoCaption>Company Registration No. Caption</CompanyRegistrationNoCaption>\r\n      <CompanyBankName>Company Bank Name</CompanyBankName>\r\n      <CompanyBankNameCaption>Company Bank Name Caption</CompanyBankNameCaption>\r\n      <CompanyBankAccountNo>Company Bank Account No.</CompanyBankAccoun');
        Observer.Expect('ext_false_5', 'tNo>\r\n      <CompanyBankAccountNoCaption>Company Bank Account No. Caption</CompanyBankAccountNoCaption>\r\n      <CompanyBankBranchNo>Company Bank Branch No.</CompanyBankBranchNo>\r\n      <CompanyBankBranchNoCaption>Company Bank Branch No. Caption</CompanyBankBranchNoCaption>\r\n      <CompanyIBAN>Company IBAN</CompanyIBAN>\r\n      <CompanyIBANCaption>Company IBAN Caption</CompanyIBANCaption>\r\n      <CompanyBankSWIFT>Company Bank SWIFT</CompanyBankSWIFT>\r\n      <CompanyBankSWIFTCaption>Company Bank SWIFT Caption</CompanyBankSWIFTCaption>\r\n      <CompanyGiroNo>Company Giro No.</CompanyGiroNo>\r\n      <CompanyGiroNoCaption>Company Giro No. Caption</CompanyGiroNoCaption>\r\n    </CompanyMetadata>\r\n  </B');
        Observer.Expect('ext_false_6', 'CReportInformation>\r\n  <Rows>\r\n    <RowExtra>RowExtra</RowExtra>\r\n    <RowName>RowName</RowName>\r\n    <RowNo>RowNo</RowNo>\r\n  </Rows>\r\n</NavWordReportXmlPart>');
        Observer.Ignore('ext_false_0'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;




}
