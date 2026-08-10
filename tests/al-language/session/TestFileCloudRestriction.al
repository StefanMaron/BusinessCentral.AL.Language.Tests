// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none
// BC versions: 27.5+
//
// CLAIM: the File data type's direct server-filesystem methods are refused in Cloud.
// This asserts real, provable Cloud behavior against a live call -- not an assumption.

codeunit 60876 "Test File Cloud Restriction"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure File_Exists_CloudSandbox_Throws()
    var
        Result: Boolean;
    begin
        asserterror Result := File.Exists('C:\test.txt');
        Assert.IsTrue(GetLastErrorText() <> '', 'File.Exists must throw in the Cloud sandbox');
    end;
}
