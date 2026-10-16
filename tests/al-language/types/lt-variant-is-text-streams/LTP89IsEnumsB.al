// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), enum LT P89 Color (74626)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74629 "LT P89 Is Enums B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsObjectType() then
            R += 'ObjectType,';
        if V.IsReportFormat() then
            R += 'ReportFormat,';
        if V.IsTableConnectionType() then
            R += 'TableConnectionType,';
        if V.IsTestPermissions() then
            R += 'TestPermissions,';
        if V.IsTextEncoding() then
            R += 'TextEncoding,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsBigInteger() then
            R += 'BigInteger,';
        if V.IsText() then
            R += 'Text,';
        if V.IsCode() then
            R += 'Code,';
        if V.IsChar() then
            R += 'Char,';
        if V.IsByte() then
            R += 'Byte,';
        if V.IsBoolean() then
            R += 'Boolean,';
        exit(R);
    end;

    [Test]
    procedure ObjectType_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ObjectType;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ObjectType::Table;
        V := X;
        Observer.Observe('table', Flags(V));
        Observer.Observe('table_format', Format(X));
        V := Format(X);
        Observer.Observe('table_text', Flags(V));
        X := ObjectType::Codeunit;
        V := X;
        Observer.Observe('codeunit', Flags(V));
        Observer.Observe('codeunit_format', Format(X));
        V := Format(X);
        Observer.Observe('codeunit_text', Flags(V));
        X := ObjectType::Page;
        V := X;
        Observer.Observe('page', Flags(V));
        Observer.Observe('page_format', Format(X));
        V := Format(X);
        Observer.Observe('page_text', Flags(V));
        V := ObjectType::Table;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure ReportFormat_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ReportFormat;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ReportFormat::Pdf;
        V := X;
        Observer.Observe('pdf', Flags(V));
        Observer.Observe('pdf_format', Format(X));
        V := Format(X);
        Observer.Observe('pdf_text', Flags(V));
        X := ReportFormat::Word;
        V := X;
        Observer.Observe('word', Flags(V));
        Observer.Observe('word_format', Format(X));
        V := Format(X);
        Observer.Observe('word_text', Flags(V));
        X := ReportFormat::Excel;
        V := X;
        Observer.Observe('excel', Flags(V));
        Observer.Observe('excel_format', Format(X));
        V := Format(X);
        Observer.Observe('excel_text', Flags(V));
        V := ReportFormat::Pdf;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure TableConnectionType_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: TableConnectionType;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := TableConnectionType::CRM;
        V := X;
        Observer.Observe('crm', Flags(V));
        Observer.Observe('crm_format', Format(X));
        V := Format(X);
        Observer.Observe('crm_text', Flags(V));
        X := TableConnectionType::ExternalSQL;
        V := X;
        Observer.Observe('externalsql', Flags(V));
        Observer.Observe('externalsql_format', Format(X));
        V := Format(X);
        Observer.Observe('externalsql_text', Flags(V));
        V := TableConnectionType::CRM;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure TestPermissions_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: TestPermissions;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := TestPermissions::Disabled;
        V := X;
        Observer.Observe('disabled', Flags(V));
        Observer.Observe('disabled_format', Format(X));
        V := Format(X);
        Observer.Observe('disabled_text', Flags(V));
        X := TestPermissions::Restrictive;
        V := X;
        Observer.Observe('restrictive', Flags(V));
        Observer.Observe('restrictive_format', Format(X));
        V := Format(X);
        Observer.Observe('restrictive_text', Flags(V));
        X := TestPermissions::NonRestrictive;
        V := X;
        Observer.Observe('nonrestrictive', Flags(V));
        Observer.Observe('nonrestrictive_format', Format(X));
        V := Format(X);
        Observer.Observe('nonrestrictive_text', Flags(V));
        X := TestPermissions::InheritFromTestCodeunit;
        V := X;
        Observer.Observe('inheritfromtestcodeunit', Flags(V));
        Observer.Observe('inheritfromtestcodeunit_format', Format(X));
        V := Format(X);
        Observer.Observe('inheritfromtestcodeunit_text', Flags(V));
        V := TestPermissions::Disabled;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure TextEncoding_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: TextEncoding;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := TextEncoding::UTF8;
        V := X;
        Observer.Observe('utf8', Flags(V));
        Observer.Observe('utf8_format', Format(X));
        V := Format(X);
        Observer.Observe('utf8_text', Flags(V));
        X := TextEncoding::UTF16;
        V := X;
        Observer.Observe('utf16', Flags(V));
        Observer.Observe('utf16_format', Format(X));
        V := Format(X);
        Observer.Observe('utf16_text', Flags(V));
        X := TextEncoding::MSDos;
        V := X;
        Observer.Observe('msdos', Flags(V));
        Observer.Observe('msdos_format', Format(X));
        V := Format(X);
        Observer.Observe('msdos_text', Flags(V));
        X := TextEncoding::Windows;
        V := X;
        Observer.Observe('windows', Flags(V));
        Observer.Observe('windows_format', Format(X));
        V := Format(X);
        Observer.Observe('windows_text', Flags(V));
        V := TextEncoding::UTF8;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure NearTypes()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,C;
        E: Enum "LT P89 Color";
        I: Integer;
        Bi: BigInteger;
        T: Text;
        C: Code[10];
        V: Variant;
    begin
        V := O; Observer.Observe('option', Flags(V));
        V := E; Observer.Observe('enum', Flags(V));
        V := I; Observer.Observe('integer', Flags(V));
        V := Bi; Observer.Observe('biginteger', Flags(V));
        T := 'x'; V := T; Observer.Observe('text', Flags(V));
        C := 'X'; V := C; Observer.Observe('code', Flags(V));
        V := true; Observer.Observe('boolean', Flags(V));
        Observer.Finish();
    end;
}
