// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fileupload/fileupload-createinstream-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A FileUpload variable no client filled (see types/TestHttpRequestFileUploadFieldErrorContracts.al): CreateInStream with no encoding and with UTF8, UTF16, MSDos and Windows
// opens a stream that is at its end (EOS true, Length 0, Position 1); ReadText answers 0 and reads '', Read(Byte) raises "Invalid data encountered in stream, unable to read
// text." / InvalidStreamData; a copy (`Copy := Upload`), a Clear'ed variable and a FileUpload passed by value or var all behave the same, FileName() reads ''.
// Fixtures used: self-contained codeunit 69546
// BC versions: 27.5

codeunit 69546 "PR File Upload Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(Upload: FileUpload): Text
    var
        InS: InStream;
    begin
        Upload.CreateInStream(InS);
        exit('eos=' + Format(InS.EOS()));
    end;

    local procedure DescribeVar(var Upload: FileUpload): Text
    var
        InS: InStream;
    begin
        Upload.CreateInStream(InS, TextEncoding::UTF8);
        exit('eos=' + Format(InS.EOS()));
    end;

    [Test]
    procedure CreateInStream_Encodings_OnUnfilled()
    var
        Upload: FileUpload;
        InS: InStream;
        Text: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Upload.CreateInStream(InS);
        Observer.Observe('default_eos', Format(InS.EOS()));
        Observer.Observe('default_length', Format(InS.Length()));
        Observer.Observe('default_position', Format(InS.Position()));
        Upload.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('utf8_eos', Format(InS.EOS()));
        Upload.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('utf16_eos', Format(InS.EOS()));
        Upload.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('msdos_eos', Format(InS.EOS()));
        Upload.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('windows_eos', Format(InS.EOS()));
        Observer.Expect('default_eos', 'Yes');
        Observer.Expect('default_length', '0');
        Observer.Expect('default_position', '1');
        Observer.Expect('utf8_eos', 'Yes');
        Observer.Expect('utf16_eos', 'Yes');
        Observer.Expect('msdos_eos', 'Yes');
        Observer.Expect('windows_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromUnfilledStream()
    var
        Upload: FileUpload;
        InS: InStream;
        Text: Text;
        B: Byte;
        Observer: Codeunit "Probe Observer";
    begin
        Upload.CreateInStream(InS);
        Observer.Observe('readtext_result', Format(InS.ReadText(Text)));
        Observer.Observe('readtext_value', '[' + Text + ']');
        asserterror InS.Read(B);
        Observer.ObserveError('read_byte');
        Observer.Expect('readtext_result', '0');
        Observer.Expect('readtext_value', '[]');
        Observer.Expect('read_byte|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('read_byte|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Unfilled_AssignClearAndPass()
    var
        Upload: FileUpload;
        Copy: FileUpload;
        Name: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Copy := Upload;
        Name := Copy.FileName();
        Observer.Observe('copy_filename', '[' + Name + ']');
        Observer.Observe('copy_stream', Describe(Copy));
        Clear(Upload);
        Observer.Observe('cleared_filename', '[' + Upload.FileName() + ']');
        Observer.Observe('cleared_stream', Describe(Upload));
        Observer.Observe('by_value', Describe(Upload));
        Observer.Observe('by_var_utf8', DescribeVar(Upload));
        Observer.Expect('copy_filename', '[]');
        Observer.Expect('copy_stream', 'eos=Yes');
        Observer.Expect('cleared_filename', '[]');
        Observer.Expect('cleared_stream', 'eos=Yes');
        Observer.Expect('by_value', 'eos=Yes');
        Observer.Expect('by_var_utf8', 'eos=Yes');
        Observer.Verify();
    end;
}
