// BC Language Edge Cases Contract Tests
// Tests obscure AL language behavioral contracts
// Runtime: 16.1, Target: Cloud
// Fixtures: IALTCompute (interface), ALTDouble (60011), ALTSquare (60012), ALT Status enum, ALT Universal table

codeunit 60165 "Test Language Edge Cases"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Test Initialization ──────────────────────────────────────────────────
    procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // ── Codeunit Variable Contracts ──────────────────────────────────────────

    [Test]
    procedure CodeunitVariable_DirectMethodCall_NoRunRequired()
    var
        D: Codeunit ALTDouble;
    begin
        // In AL, a codeunit variable can be called directly without Codeunit.Run()
        Assert.AreEqual(10, D.Compute(5), 'Codeunit variable must allow direct method calls without Run()');
    end;

    [Test]
    procedure CodeunitRun_Success_ReturnsTrue()
    var
        Result: Boolean;
    begin
        // Codeunit.Run must return true when codeunit executes successfully
        Result := Codeunit.Run(Codeunit::ALTFixtureCleanup);
        Assert.IsTrue(Result, 'Codeunit.Run must return true when codeunit executes successfully');
    end;

    [Test]
    procedure CodeunitRun_ValidCodeunit_ReturnsTrueWithoutError()
    var
        Result: Boolean;
    begin
        // Codeunit.Run on valid codeunit returns true and does not throw
        Result := Codeunit.Run(Codeunit::ALTDouble);
        Assert.IsTrue(Result, 'Codeunit.Run on valid codeunit must return true');
    end;

    // ── Interface Contracts ──────────────────────────────────────────────────

    [Test]
    procedure Interface_AssignedCodeunitVariable_CallsMethod()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
    begin
        // Assigned interface variable must call correct implementation
        C := D;
        Assert.AreEqual(8, C.Compute(4), 'Assigned interface must call correct implementation');
    end;

    [Test]
    procedure Interface_Reassign_SwitchesImplementation()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        S: Codeunit ALTSquare;
        R1: Integer;
        R2: Integer;
    begin
        // Reassigning interface variable must switch implementation
        C := D;
        R1 := C.Compute(5);  // 2*5=10
        C := S;
        R2 := C.Compute(5);  // 5^2=25
        Assert.AreEqual(10, R1, 'ALTDouble.Compute(5) via interface must return 10');
        Assert.AreEqual(25, R2, 'ALTSquare.Compute(5) via interface after reassign must return 25');
    end;

    // ── Enum Ordinals Contracts ──────────────────────────────────────────────

    [Test]
    procedure Enum_Ordinals_IncludesBlanks()
    var
        Ordinals: List of [Integer];
    begin
        // Ordinals() must return list including the blank ordinal (0)
        Ordinals := "ALT Status".Ordinals();
        Assert.IsTrue(Ordinals.Count() >= 4, 'ALT Status must have at least 4 ordinals including blank');
        Assert.IsTrue(Ordinals.Contains(0), 'Ordinals() must include the blank ordinal (0)');
    end;

    [Test]
    procedure Enum_Ordinals_ContainsAllDefinedValues()
    var
        Ordinals: List of [Integer];
    begin
        // Ordinals() must return all defined enum values
        Ordinals := "ALT Status".Ordinals();
        Assert.IsTrue(Ordinals.Contains(1), 'Ordinals() must include ordinal 1 (Draft)');
        Assert.IsTrue(Ordinals.Contains(2), 'Ordinals() must include ordinal 2 (Active)');
        Assert.IsTrue(Ordinals.Contains(3), 'Ordinals() must include ordinal 3 (Closed)');
    end;

    [Test]
    procedure Option_Uninitialized_DefaultsToZeroOrdinal()
    var
        Rec: Record "ALT Universal";
    begin
        // Uninitialized Option field must default to ordinal 0
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        Assert.AreEqual(0, Rec."Option Field", 'Uninitialized Option field must default to ordinal 0 (first option)');
    end;

    [Test]
    procedure Enum_Uninitialized_DefaultsToZeroOrdinal()
    var
        S: Enum "ALT Status";
    begin
        // Uninitialized Enum variable must be ordinal 0
        Assert.AreEqual(0, S.AsInteger(), 'Uninitialized Enum must default to ordinal 0');
    end;

    // ── Format() of Zero/Empty Values ────────────────────────────────────────

    [Test]
    procedure Format_ZeroDate_IsEmptyString()
    begin
        // Format(0D) must return empty string
        Assert.AreEqual('', Format(0D), 'Format(0D) must return empty string (zero date has no representation)');
    end;

    [Test]
    procedure Format_ZeroTime_IsEmptyString()
    begin
        // Format(0T) must return empty string
        Assert.AreEqual('', Format(0T), 'Format(0T) must return empty string (zero time has no representation)');
    end;

    [Test]
    procedure Format_ZeroDateTime_IsEmptyString()
    begin
        // Format(0DT) must return empty string
        Assert.AreEqual('', Format(0DT), 'Format(0DT) must return empty string (zero datetime has no representation)');
    end;

    [Test]
    procedure Format_EmptyGuid_ReturnsFormattedZeros()
    var
        G: Guid;
        S: Text;
    begin
        // Format(empty Guid) must return non-empty braced format and IsNullGuid must be true
        S := Format(G);
        Assert.AreNotEqual('', S, 'Format(empty Guid) must return non-empty string (braced zeros)');
        Assert.IsTrue(IsNullGuid(G), 'Uninitialized Guid must be null Guid');
    end;

    // ── ClearLastError() Contracts ───────────────────────────────────────────

    [Test]
    procedure ClearLastError_ClearsErrorCode()
    begin
        // ClearLastError must clear GetLastErrorCode() to empty string
        asserterror Error('test');
        Assert.AreNotEqual('', GetLastErrorCode(), 'Before ClearLastError, error code must be non-empty');
        ClearLastError();
        Assert.AreEqual('', GetLastErrorCode(), 'After ClearLastError, GetLastErrorCode must return empty string');
    end;

    [Test]
    procedure ClearLastError_ClearsErrorText()
    begin
        // ClearLastError must clear GetLastErrorText() to empty string
        asserterror Error('clear me');
        Assert.AreEqual('clear me', GetLastErrorText(), 'Error text must match');
        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'After ClearLastError, GetLastErrorText must return empty string');
    end;
}
