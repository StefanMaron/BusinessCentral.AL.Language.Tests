// A top-level test runner with TestIsolation = Function (AL Runner issue #4826).
//
// The same shape as Microsoft's "Test Runner - Isol. Codeunit" (130450) with one property
// changed, so Run-TestsInBcContainer -testRunnerCodeunitId 61300 drives it through the
// ordinary AL Test Tool and records a result per test method. The question it answers: does
// BC give each [Test] method a fresh test-codeunit instance, or run them all on one?
// See "Isol Probe Fixture" (61302) for the observables.
namespace ALLanguage.IsolationProbe;

using System.TestTools.TestRunner;

codeunit 61300 "Isol Probe Runner Function"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
    TestIsolation = Function;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    begin
        ALTestSuite.Get(Rec."Test Suite");
        CurrentTestMethodLine.Copy(Rec);
        TestRunnerMgt.RunTests(Rec);
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        exit(
          TestRunnerMgt.PlatformBeforeTestRun(
            CodeunitID, CopyStr(CodeunitName, 1, 30), CopyStr(FunctionName, 1, 128), FunctionTestPermissions, ALTestSuite.Name, CurrentTestMethodLine.GetFilter("Line No.")));
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        TestRunnerMgt.PlatformAfterTestRun(
          CodeunitID, CopyStr(CodeunitName, 1, 30), CopyStr(FunctionName, 1, 128), FunctionTestPermissions, IsSuccess, ALTestSuite.Name,
          CurrentTestMethodLine.GetFilter("Line No."));
    end;

    var
        ALTestSuite: Record "AL Test Suite";
        CurrentTestMethodLine: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
}
