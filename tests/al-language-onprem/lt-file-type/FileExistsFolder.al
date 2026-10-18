// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins File.Exists for a folder name, a folder name with a trailing separator, a name with leading blanks and a file that was just created and erased.
// BC versions: 29 (27 and 28 by CI)
codeunit 61285 "LT Q File Exists Folder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Exists_Folder_And_Blank_Names()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        P: Text;
        Dir: Text;
    begin
        Dir := TemporaryPath();
        Observer.Observe('folder', Format(File.Exists(Dir)));
        Observer.Observe('folder_trimmed', Format(File.Exists(CopyStr(Dir, 1, StrLen(Dir) - 1))));
        Observer.Observe('blank', Format(File.Exists(' ')));
        P := Dir + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp';
        F.Create(P);
        F.Close();
        Observer.Observe('file', Format(File.Exists(P)));
        Observer.Observe('file_leading_blank', Format(File.Exists(' ' + P)));
        File.Erase(P);
        Observer.Observe('file_erased', Format(File.Exists(P)));
        Observer.Finish();
    end;
}
