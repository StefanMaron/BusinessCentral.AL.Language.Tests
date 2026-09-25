// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPAROKP Probe (60584), Assert (60021) -- and Base Application pages
//                116 "G/L Registers", 99000798 "Routing Links", 5925 "Fault Areas"
//
// The same three RunObject kinds codeunit 60559 pins, reached through actions on pages that
// ship PRECOMPILED in Base Application instead of pages this app compiles.
//
// BC answers these exactly as it answers 60559's own pages: a codeunit target runs on the host
// page's current row, and report and xmlport targets are refused by the TestPage surface with
// "The method RunReport / RunXmlPort is not supported for TestPages." The arms exist for the
// route, not for a new answer. A client that has only the action's declared NAME for a
// precompiled page -- AL Runner reads it from SymbolReference.json, which states RunObject as
// a bare name with no object type -- has to work out the kind itself, and every action below
// names an object that exactly one kind answers in Base Application:
//
//   G/L Registers  "General Ledger"                     -> codeunit 235 "G/L Reg.-Gen. Ledger"
//   Routing Links  "Routing Sheet"                      -> report 99000787 "Routing Sheet"
//   Fault Areas    "Import IRIS to Area/Symptom Code"   -> xmlport 5900
//
// Written by agent stma-auto2-5, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4582.

codeunit 60571 "TPAROKP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // CODEUNIT. The host is parked on a register this test inserted, between two others, so
    // the register number the codeunit reports can only be the host's current row: a codeunit
    // handed a fresh record reports 0, and one handed the first or last row reports a
    // neighbour. The probe marks OnBeforeRun handled, so codeunit 235 exits before PAGE.Run.
    [Test]
    procedure PrecompiledPageRunObjectNamingACodeunitRunsItOnTheHostsRow()
    var
        GLRegister: Record "G/L Register";
        Probe: Codeunit "TPAROKP Probe";
        Host: TestPage "G/L Registers";
    begin
        InsertRegister(1999999901);
        InsertRegister(1999999902);
        InsertRegister(1999999903);
        Probe.Arm();

        Host.OpenView();
        GLRegister.Get(1999999902);
        Assert.IsTrue(Host.GoToRecord(GLRegister), 'GoToRecord must find the inserted register');
        Host."General Ledger".Invoke();
        Probe.Disarm();

        Assert.IsTrue(Probe.GetRan(),
            'a RunObject action naming a codeunit on a precompiled page must run it: OnBeforeRun never fired');
        Assert.AreEqual(1999999902, Probe.GetRegisterNoSeen(),
            'the codeunit target must be handed the host page''s current row');
    end;

    // REPORT. Refused before anything runs, with BC's own message -- the same one 60559's
    // source-compiled report arms measure.
    [Test]
    procedure PrecompiledPageRunObjectNamingAReportIsRefusedByTheTestPageSurface()
    var
        Host: TestPage "Routing Links";
    begin
        Host.OpenView();
        asserterror Host."Routing Sheet".Invoke();

        Assert.ExpectedError('The method RunReport is not supported for TestPages.');
    end;

    // XMLPORT. Likewise refused, naming RunXmlPort rather than RunReport, which is what tells
    // the two kinds apart: a client that resolved the xmlport as a report would raise the
    // report's message here.
    [Test]
    procedure PrecompiledPageRunObjectNamingAnXmlPortIsRefusedByTheTestPageSurface()
    var
        Host: TestPage "Fault Areas";
    begin
        Host.OpenView();
        asserterror Host."Import IRIS to Area/Symptom Code".Invoke();

        Assert.ExpectedError('The method RunXmlPort is not supported for TestPages.');
    end;

    local procedure InsertRegister(No: Integer)
    var
        GLRegister: Record "G/L Register";
    begin
        if GLRegister.Get(No) then
            GLRegister.Delete();
        GLRegister.Init();
        GLRegister."No." := No;
        GLRegister.Insert();
    end;
}
