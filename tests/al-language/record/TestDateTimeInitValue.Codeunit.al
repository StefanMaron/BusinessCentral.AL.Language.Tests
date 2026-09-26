// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: tables 67512 and 67513, tableextensions 67512 and 67513, all in this folder.
//
// CLAIM: the compiler accepts InitValue = 0DT on a DateTime field and the closing-date literal
// InitValue = C20260101D on a Date field, but Init() on the table then raises an error, because
// the service tier cannot evaluate the InitValue text the compiler stored for either shape:
//   0DT        -> The value "01/01/0001 00:00:00" can't be evaluated into type DateTime.
//   C20260101D -> The format of the Date 'C20260101D' does not match your device's date settings.
// The same holds on a table compiled in this app and on a field a tableextension adds to a Base
// Application table. Each test writes a field first: Init() on a record variable nothing has been
// written to yet does not evaluate any InitValue, so it raises nothing; reading the field does (the
// last test pins both).
// TestDateInitValue (67510) pins the Date literals Init() does apply.
//
// Written by agent stma-auto2-3 for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4794.
codeunit 67512 "Test DateTime InitValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ZeroDateTimeErr: Label 'The value "01/01/0001 00:00:00" can''t be evaluated into type DateTime.', Locked = true;
        ClosingDateErr: Label 'The format of the Date ''C20260101D'' does not match your device''s date settings.', Locked = true;

    [Test]
    procedure DateTimeInitValue_Table_ZeroDateTimeInitValueFailsInit()
    var
        Rec: Record "ALT DateTime Init Value";
    begin
        Rec."Zero DateTime" := CreateDateTime(20300615D, 120000T);
        asserterror Rec.Init();
        Assert.ExpectedError(ZeroDateTimeErr);
    end;

    [Test]
    procedure DateTimeInitValue_Table_ClosingDateInitValueFailsInit()
    var
        Rec: Record "ALT Closing Date Init Value";
    begin
        Rec."Closing Date" := 20300615D;
        asserterror Rec.Init();
        Assert.ExpectedError(ClosingDateErr);
    end;

    [Test]
    procedure DateTimeInitValue_TableExtOnBaseAppTable_ZeroDateTimeInitValueFailsInit()
    var
        IndustryGroup: Record "Industry Group";
    begin
        IndustryGroup."ALT Ext Zero DateTime" := CreateDateTime(20300615D, 120000T);
        asserterror IndustryGroup.Init();
        Assert.ExpectedError(ZeroDateTimeErr);
    end;

    [Test]
    procedure DateTimeInitValue_TableExtOnBaseAppTable_ClosingDateInitValueFailsInit()
    var
        MailingGroup: Record "Mailing Group";
    begin
        MailingGroup."ALT Ext Closing Date" := 20300615D;
        asserterror MailingGroup.Init();
        Assert.ExpectedError(ClosingDateErr);
    end;

    [Test]
    procedure DateTimeInitValue_Table_UntouchedRecordRaisesOnReadNotOnInit()
    var
        Rec: Record "ALT DateTime Init Value";
        Value: DateTime;
    begin
        // Nothing has been written to Rec, so Init() has no field buffer to reset and raises nothing.
        Rec.Init();

        // Reading the field of the untouched record evaluates its InitValue, and that raises.
        asserterror Value := Rec."Zero DateTime";
        Assert.ExpectedError(ZeroDateTimeErr);
    end;
}
