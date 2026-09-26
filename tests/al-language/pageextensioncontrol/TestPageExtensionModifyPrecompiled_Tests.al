// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page 682 "Schedule a Report" with its
//                pageextension 682 "Schedule a Report Ext", both of which ship PRECOMPILED in
//                Base Application.
//
// CLAIM: when a precompiled pageextension uses modify(<control>) to set Enabled on a control the
// base page declares, the control answers the EXTENSION's Enabled. The base page declares no
// Enabled on "Printer Name"; the extension sets
//   Enabled = Rec."Report Output Type" = Rec."Report Output Type"::Print;
// so the field is enabled while the output type is Print and disabled for any other type.
//
// HOW THE ROW GETS ITS OUTPUT TYPE: validating "Report Output Type" is avoided on purpose. Its
// OnAfterValidate (tableextension "Job Queue Entry Ext.") resets Print to PDF with a Message on
// SaaS and otherwise looks up the client's default printer, neither of which this test is about.
// Instead the page's own SetParameters fills its temporary row, and its OnGetReportDescription
// event hands a manually bound subscriber the row BEFORE it is inserted; the subscriber assigns
// the output type without validating it. Report 101 "Customer - List" is the report id, only
// because "Object ID to Run" must name a report that exists.
//
// Each arm closes through Cancel: an OK close would enqueue a job queue entry.
//
// APPLICATION AREA: both fields declare ApplicationArea = Basic, Suite. Each arm enables those
// and restores the previous areas before it asserts.
//
// Written by agent stma-auto2-14, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4761.

codeunit 67403 "PXCM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure PrinterNameEnabled(OutputType: Enum "Job Queue Report Output Type") Enabled: Boolean
    var
        OutputTypeSetter: Codeunit "PXCM Output Type Setter";
        ScheduleAReportPage: Page "Schedule a Report";
        ScheduleAReport: TestPage "Schedule a Report";
        PreviousAreas: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');
        OutputTypeSetter.SetOutputType(OutputType);
        BindSubscription(OutputTypeSetter);

        ScheduleAReportPage.SetParameters(Report::"Customer - List", '');
        ScheduleAReport.Trap();
        ScheduleAReportPage.Run();
        // Setup check: the row carries the output type the subscriber assigned.
        ScheduleAReport."Report Output Type".AssertEquals(OutputType);
        Enabled := ScheduleAReport."Printer Name".Enabled();
        ScheduleAReport.Cancel().Invoke();

        UnbindSubscription(OutputTypeSetter);
        ApplicationArea(PreviousAreas);
    end;

    [Test]
    procedure PrecompiledPageExtModify_PrintOutput_PrinterNameIsEnabled()
    var
        Enabled: Boolean;
    begin
        Enabled := PrinterNameEnabled(Enum::"Job Queue Report Output Type"::Print);

        Assert.IsTrue(Enabled, '"Printer Name" (Enabled = Rec."Report Output Type" = Print, set by modify() in pageextension "Schedule a Report Ext") must be enabled for Print output.');
    end;

    [Test]
    procedure PrecompiledPageExtModify_PdfOutput_PrinterNameIsDisabled()
    var
        Enabled: Boolean;
    begin
        Enabled := PrinterNameEnabled(Enum::"Job Queue Report Output Type"::PDF);

        Assert.IsFalse(Enabled, '"Printer Name" (Enabled = Rec."Report Output Type" = Print, set by modify() in pageextension "Schedule a Report Ext") must be disabled for PDF output.');
    end;

    [Test]
    procedure PrecompiledPageExtModify_ExcelOutput_PrinterNameIsDisabled()
    var
        Enabled: Boolean;
    begin
        Enabled := PrinterNameEnabled(Enum::"Job Queue Report Output Type"::Excel);

        Assert.IsFalse(Enabled, '"Printer Name" (Enabled = Rec."Report Output Type" = Print, set by modify() in pageextension "Schedule a Report Ext") must be disabled for Excel output.');
    end;
}

codeunit 67404 "PXCM Output Type Setter"
{
    EventSubscriberInstance = Manual;

    var
        OutputTypeToSet: Enum "Job Queue Report Output Type";

    procedure SetOutputType(OutputType: Enum "Job Queue Report Output Type")
    begin
        OutputTypeToSet := OutputType;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Schedule a Report", 'OnGetReportDescription', '', false, false)]
    local procedure AssignOutputTypeBeforeInsert(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry."Report Output Type" := OutputTypeToSet;
    end;
}
