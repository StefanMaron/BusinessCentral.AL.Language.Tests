// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-init-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Date Init Value (67510) and ALT Date Init Job Ext (67510), both in this folder.
//
// CLAIM: a Date field's InitValue written as an AL date literal (20260101D) is the value Init()
// leaves in the field, both on a table compiled in this app and on a field a tableextension adds
// to a Base Application table. InitValue = 0D leaves the field blank, like a field with no
// InitValue. ALT Init Value (60024) already pins Integer, Text, Boolean, Decimal and Time; no
// corpus test pinned a Date InitValue.
//
// Written by agent stma-auto2-3 for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4633.
codeunit 67510 "Test Date InitValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DateInitValue_Table_InitSetsTheDeclaredDate()
    var
        Rec: Record "ALT Date Init Value";
    begin
        Rec.Init();

        Assert.AreEqual(20260101D, Rec."Start Date", 'Init() must set Start Date to its InitValue 20260101D');
        Assert.AreEqual(20240229D, Rec."Leap Date", 'Init() must set Leap Date to its InitValue 20240229D');
    end;

    [Test]
    procedure DateInitValue_Table_ZeroAndAbsentInitValueLeaveTheFieldBlank()
    var
        Rec: Record "ALT Date Init Value";
    begin
        Rec.Init();

        Assert.AreEqual(0D, Rec."Zero Date", 'InitValue = 0D must leave the field blank');
        Assert.AreEqual(0D, Rec."Plain Date", 'a Date field with no InitValue must be blank after Init()');
        asserterror Rec.TestField("Zero Date");
        Assert.ExpectedError('Zero Date');
    end;

    [Test]
    procedure DateInitValue_Table_InitOverwritesAnAssignedDate()
    var
        Rec: Record "ALT Date Init Value";
    begin
        Rec."Start Date" := 20300615D;
        Rec."Plain Date" := 20300615D;

        Rec.Init();

        Assert.AreEqual(20260101D, Rec."Start Date", 'Init() must restore Start Date to its InitValue');
        Assert.AreEqual(0D, Rec."Plain Date", 'Init() must clear a Date field that has no InitValue');
    end;

    [Test]
    procedure DateInitValue_TableExtOnBaseAppTable_InitSetsTheDeclaredDate()
    var
        Job: Record Job;
    begin
        Job."ALT Ext Start Date" := 20300615D;

        Job.Init();

        Assert.AreEqual(20260101D, Job."ALT Ext Start Date", 'Init() must set the extension field to its InitValue 20260101D');
    end;

    [Test]
    procedure DateInitValue_TableExtOnBaseAppTable_ZeroAndAbsentInitValueLeaveTheFieldBlank()
    var
        Job: Record Job;
    begin
        Job."ALT Ext Zero Date" := 20300615D;
        Job."ALT Ext Plain Date" := 20300615D;

        Job.Init();

        Assert.AreEqual(0D, Job."ALT Ext Zero Date", 'InitValue = 0D must leave the extension field blank');
        Assert.AreEqual(0D, Job."ALT Ext Plain Date", 'an extension Date field with no InitValue must be blank after Init()');
        asserterror Job.TestField("ALT Ext Zero Date");
        Assert.ExpectedError('ALT Ext Zero Date');
    end;
}
