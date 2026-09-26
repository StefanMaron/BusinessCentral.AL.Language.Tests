// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: tables 67512 and 67513, tableextensions 67512 and 67513, all in this folder.
//
// CLAIM: Init() applies a DateTime field's InitValue = 0DT (the field is blank afterwards) and a
// Date field's closing-date InitValue C20260101D (the field holds ClosingDate(20260101D), not the
// normal date 20260101D), both on a table compiled in this app and on a field a tableextension
// adds to a Base Application table. TestDateInitValue (67510) pins normal Date literals and 0D.
//
// Written by agent stma-auto2-3 for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4794.
codeunit 67512 "Test DateTime InitValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DateTimeInitValue_Table_ZeroDateTimeLeavesTheFieldBlank()
    var
        Rec: Record "ALT DateTime Init Value";
    begin
        Rec."Zero DateTime" := CreateDateTime(20300615D, 120000T);
        Rec."Plain DateTime" := CreateDateTime(20300615D, 120000T);

        Rec.Init();

        Assert.AreEqual(0DT, Rec."Zero DateTime", 'InitValue = 0DT must leave the field blank after Init()');
        Assert.AreEqual(0DT, Rec."Plain DateTime", 'a DateTime field with no InitValue must be blank after Init()');
    end;

    [Test]
    procedure DateTimeInitValue_Table_ClosingDateInitValueIsTheClosingDate()
    var
        Rec: Record "ALT Closing Date Init Value";
    begin
        Rec."Closing Date" := 20300615D;

        Rec.Init();

        Assert.AreEqual(ClosingDate(20260101D), Rec."Closing Date", 'Init() must set the field to its InitValue C20260101D');
        Assert.AreNotEqual(20260101D, Rec."Closing Date", 'a closing-date InitValue must not collapse to the normal date');
        Assert.AreEqual(20260101D, NormalDate(Rec."Closing Date"), 'the closing date must be the one for 2026-01-01');
    end;

    [Test]
    procedure DateTimeInitValue_TableExtOnBaseAppTable_ZeroDateTimeLeavesTheFieldBlank()
    var
        IndustryGroup: Record "Industry Group";
    begin
        IndustryGroup."ALT Ext Zero DateTime" := CreateDateTime(20300615D, 120000T);

        IndustryGroup.Init();

        Assert.AreEqual(0DT, IndustryGroup."ALT Ext Zero DateTime", 'InitValue = 0DT must leave the extension field blank after Init()');
    end;

    [Test]
    procedure DateTimeInitValue_TableExtOnBaseAppTable_ClosingDateInitValueIsTheClosingDate()
    var
        MailingGroup: Record "Mailing Group";
    begin
        MailingGroup."ALT Ext Closing Date" := 20300615D;

        MailingGroup.Init();

        Assert.AreEqual(ClosingDate(20260101D), MailingGroup."ALT Ext Closing Date", 'Init() must set the extension field to its InitValue C20260101D');
        Assert.AreNotEqual(20260101D, MailingGroup."ALT Ext Closing Date", 'a closing-date InitValue must not collapse to the normal date');
    end;
}
