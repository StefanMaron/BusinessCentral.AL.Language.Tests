// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: none (the table and its tableextension are declared in this file)
// Note: pins that a procedure declared in a TABLEEXTENSION runs normally while code coverage
//       is recording. The platform's recorder resolves the metadata of every object whose
//       method scope it enters, tableextensions included, so a call into an extension's
//       procedure must neither fail nor change the procedure's result.
//
//       Written for AlRunner#5384, where the runner answered "the TableExtension object with
//       the ID ... does not exist" for that call, and, because recording stayed on after the
//       failed test, for every later call into a tableextension procedure in the same
//       process. The second test pins that the recording state does not poison what runs next.
// BC versions: 24+

table 69960 "Cov Ext Table"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 69961 "Cov Ext Table Ext" extends "Cov Ext Table"
{
    fields
    {
        field(69960; Extra; Integer) { }
    }

    procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 2);
    end;
}

codeunit 69962 "Test Code Cov Table Extension"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableExtensionProcedure_WhileRecordingCoverage_ReturnsItsResult()
    var
        Rec: Record "Cov Ext Table";
        Result: Integer;
    begin
        // [GIVEN] code coverage is recording
        CodeCoverageLog(true, false);

        // [WHEN] a procedure declared in a tableextension is called
        Result := Rec.Twice(21);
        CodeCoverageLog(false, false);

        // [THEN] it runs and returns its own result
        Assert.AreEqual(42, Result, 'the tableextension procedure must run while recording.');
    end;

    [Test]
    procedure TableExtensionProcedure_AfterRecordingStopped_StillReturnsItsResult()
    var
        Rec: Record "Cov Ext Table";
    begin
        // [GIVEN] a recording that started and stopped around a tableextension call
        CodeCoverageLog(true, false);
        Assert.AreEqual(10, Rec.Twice(5), 'the tableextension procedure must run while recording.');
        CodeCoverageLog(false, false);

        // [WHEN] the procedure is called again with nothing recording
        // [THEN] it still returns its own result, with a different argument
        Assert.AreEqual(14, Rec.Twice(7), 'the tableextension procedure must run once recording has stopped.');
        Assert.IsFalse(CodeCoverageLog(), 'recording must be off after it was stopped.');
    end;
}
