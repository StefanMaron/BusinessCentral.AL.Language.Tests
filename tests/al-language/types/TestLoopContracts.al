codeunit 60186 "Test Loop Contracts"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
        Initialize();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // ============================================================================
    // FOR LOOP TESTS — BASIC COUNTING
    // ============================================================================

    [Test]
    procedure ForLoop_CountsUpward_LowToHigh()
    var
        i: Integer;
        Sum: Integer;
    begin
        Sum := 0;
        for i := 1 to 5 do
            Sum += i;

        Assert.AreEqual(15, Sum, 'for i := 1 to 5 must sum 1+2+3+4+5 = 15');
    end;

    [Test]
    procedure ForLoop_CountsDownward_HighToLow()
    var
        i: Integer;
        Sum: Integer;
    begin
        Sum := 0;
        for i := 5 downto 1 do
            Sum += i;

        Assert.AreEqual(15, Sum, 'for i := 5 downto 1 must also sum 5+4+3+2+1 = 15');
    end;

    [Test]
    procedure ForLoop_ZeroIterations_WhenLowGreaterThanHigh()
    var
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        for i := 5 to 1 do
            Count += 1;

        Assert.AreEqual(0, Count, 'for i := 5 to 1 must execute ZERO iterations (start > end)');
    end;

    [Test]
    procedure ForLoop_ZeroIterations_Downto_WhenLowGreaterThanHigh()
    var
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        for i := 1 downto 5 do
            Count += 1;

        Assert.AreEqual(0, Count, 'for i := 1 downto 5 must execute ZERO iterations');
    end;

    [Test]
    procedure ForLoop_ExactlyOneIteration_WhenBoundsEqual()
    var
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        for i := 3 to 3 do
            Count += 1;

        Assert.AreEqual(1, Count, 'for i := 3 to 3 must execute EXACTLY one iteration');
    end;

    [Test]
    procedure ForLoop_ExactlyOneIteration_Downto_WhenBoundsEqual()
    var
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        for i := 7 downto 7 do
            Count += 1;

        Assert.AreEqual(1, Count, 'for i := 7 downto 7 must execute EXACTLY one iteration');
    end;

    [Test]
    procedure ForLoop_Variable_AtEndValue_AfterLoop()
    var
        i: Integer;
    begin
        for i := 1 to 5 do;

        Assert.AreEqual(5, i, 'After for i := 1 to 5, loop variable must equal 5 (last executed value)');
    end;

    [Test]
    procedure ForLoop_Variable_AtEndValue_Downto_AfterLoop()
    var
        i: Integer;
    begin
        for i := 5 downto 1 do;

        Assert.AreEqual(1, i, 'After for i := 5 downto 1, loop variable must equal 1 (last executed value)');
    end;

    [Test]
    procedure ForLoop_RuntimeBounds_WorkCorrectly()
    var
        Start: Integer;
        End_: Integer;
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        Start := 3;
        End_ := 7;
        for i := Start to End_ do
            Count += 1;

        Assert.AreEqual(5, Count, 'for loop with runtime-computed bounds must iterate correct number of times (3,4,5,6,7 = 5 times)');
    end;

    [Test]
    procedure ForLoop_NestedLoops_MultiplyIterations()
    var
        i: Integer;
        j: Integer;
        Count: Integer;
    begin
        Count := 0;
        for i := 1 to 3 do
            for j := 1 to 4 do
                Count += 1;

        Assert.AreEqual(12, Count, 'Nested loops 3×4 must produce 12 total iterations');
    end;

    [Test]
    procedure ForLoop_WithExitInside_StopsImmediately()
    var
        Result: Integer;
    begin
        Result := FindFirst(3);

        Assert.AreEqual(3, Result, 'for loop with exit() when i=3 must return 3');
    end;

    [Test]
    procedure ForLoop_Body_CanModifyOtherVars()
    var
        i: Integer;
        A: array[5] of Integer;
    begin
        for i := 1 to 5 do
            A[i] := i * i;

        Assert.AreEqual(1, A[1], 'A[1] must be 1^2 = 1');
        Assert.AreEqual(4, A[2], 'A[2] must be 2^2 = 4');
        Assert.AreEqual(9, A[3], 'A[3] must be 3^2 = 9');
        Assert.AreEqual(25, A[5], 'A[5] must be 5^2 = 25');
    end;

    // ============================================================================
    // WHILE LOOP TESTS
    // ============================================================================

    [Test]
    procedure WhileLoop_PreCondition_NeverExecutesIfFalse()
    var
        Count: Integer;
    begin
        Count := 0;
        while false do
            Count += 1;

        Assert.AreEqual(0, Count, 'while false do must execute ZERO iterations');
    end;

    [Test]
    procedure WhileLoop_PreCondition_ExecutesWhileTrue()
    var
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        i := 0;
        while i < 5 do
        begin
            i += 1;
            Count += 1;
        end;

        Assert.AreEqual(5, Count, 'while i < 5 must execute exactly 5 times');
    end;

    [Test]
    procedure WhileLoop_ExitWhenConditionMetMidway()
    var
        i: Integer;
        Sum: Integer;
    begin
        Sum := 0;
        i := 0;
        while i < 100 do
        begin
            i += 1;
            Sum += i;
            if i = 3 then
                i := 100;
        end;

        Assert.AreEqual(6, Sum, 'while loop forced to exit at i=3 must have sum 1+2+3=6');
    end;

    [Test]
    procedure WhileLoop_Variable_RetainsValueAfterExit()
    var
        i: Integer;
    begin
        i := 0;
        while i < 5 do
            i += 1;

        Assert.AreEqual(5, i, 'After while i < 5, i must equal 5 (the value that made condition false)');
    end;

    [Test]
    procedure WhileLoop_InfiniteWithExit_StopsAtExit()
    var
        Count: Integer;
    begin
        Count := CountToFive();

        Assert.AreEqual(5, Count, 'while loop with exit at Count=5 must return 5');
    end;

    [Test]
    procedure WhileLoop_NestedWithFor()
    var
        i: Integer;
        j: Integer;
        Sum: Integer;
    begin
        Sum := 0;
        i := 1;
        while i <= 3 do
        begin
            for j := 1 to i do
                Sum += j;
            i += 1;
        end;

        Assert.AreEqual(10, Sum, 'Nested while+for: sum 1 + (1+2) + (1+2+3) = 10');
    end;

    // ============================================================================
    // REPEAT...UNTIL LOOP TESTS
    // ============================================================================

    [Test]
    procedure RepeatUntil_AlwaysExecutesAtLeastOnce()
    var
        Count: Integer;
    begin
        Count := 0;
        repeat
            Count += 1;
        until true;

        Assert.AreEqual(1, Count, 'repeat...until true must execute EXACTLY once (post-condition)');
    end;

    [Test]
    procedure RepeatUntil_ExecutesUntilCondition()
    var
        i: Integer;
    begin
        i := 0;
        repeat
            i += 1;
        until i >= 5;

        Assert.AreEqual(5, i, 'repeat i += 1 until i >= 5 must stop when i = 5');
    end;

    [Test]
    procedure RepeatUntil_BodyAlwaysRunsOnce_EvenIfConditionInitiallyTrue()
    var
        Count: Integer;
    begin
        Count := 10;
        repeat
            Count += 1;
        until Count >= 5;

        Assert.AreEqual(11, Count, 'repeat body ALWAYS runs at least once, even if condition is already true');
    end;

    [Test]
    procedure RepeatUntil_CountsIterations()
    var
        i: Integer;
        Count: Integer;
    begin
        Count := 0;
        i := 1;
        repeat
        begin
            i += 1;
            Count += 1;
        end;
        until i > 5;

        Assert.AreEqual(5, Count, 'repeat until i > 5 must execute 5 times (i goes 2,3,4,5,6)');
    end;

    [Test]
    procedure RepeatUntil_WithNestedFor()
    var
        outer: Integer;
        inner: Integer;
        Sum: Integer;
    begin
        Sum := 0;
        outer := 0;
        repeat
        begin
            outer += 1;
            for inner := 1 to outer do
                Sum += 1;
        end;
        until outer >= 3;

        Assert.AreEqual(6, Sum, 'repeat with nested for: 1 + 2 + 3 = 6');
    end;

    // ============================================================================
    // LOOP CONTROL FLOW TESTS
    // ============================================================================

    [Test]
    procedure Loop_BreakEquivalent_WithBooleanFlag()
    var
        i: Integer;
        Found: Boolean;
        Result: Integer;
    begin
        Found := false;
        Result := 0;
        for i := 1 to 10 do
            if i = 7 then
            begin
                Result := i;
                Found := true;
            end;

        Assert.IsTrue(Found, 'Loop with flag must find value 7');
        Assert.AreEqual(7, Result, 'Result must be 7 when found');
    end;

    [Test]
    procedure Loop_AllThreeTypes_SameResult()
    var
        i: Integer;
        ForSum: Integer;
        WhileSum: Integer;
        RepeatSum: Integer;
    begin
        ForSum := 0;
        WhileSum := 0;
        RepeatSum := 0;

        for i := 1 to 5 do
            ForSum += i;

        i := 1;
        while i <= 5 do
        begin
            WhileSum += i;
            i += 1;
        end;

        i := 1;
        repeat
        begin
            RepeatSum += i;
            i += 1;
        end;
        until i > 5;

        Assert.AreEqual(ForSum, WhileSum, 'for and while sums must agree');
        Assert.AreEqual(ForSum, RepeatSum, 'for and repeat sums must agree (all = 15)');
    end;

    // ============================================================================
    // HELPER PROCEDURES
    // ============================================================================

    local procedure FindFirst(Target: Integer): Integer
    var
        i: Integer;
    begin
        for i := 1 to 10 do
            if i = Target then
                exit(i);
        exit(-1);
    end;

    local procedure CountToFive(): Integer
    var
        Count: Integer;
    begin
        Count := 0;
        while true do
        begin
            Count += 1;
            if Count = 5 then
                exit(Count);
        end;
    end;

    // corpus issue 664 (writer BN): for-loop bounds are converted to the type of the control variable (Learn: control statements).
    // A literal bound outside the Integer range does not compile: tests/must-not-compile/cases/1404. Here the bound is a BigInteger or
    // Decimal variable. Observed on BC (probe form: Observer.Finish).
    [Test]
    procedure BN_ForLoop_BoundConvertedToControlType()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Dec: Decimal;
        Count: Integer;
        R: Text;
    begin
        Big := 100000000000000;
        if TryForBig(Big, Count) then
            Observer.Observe('biginteger bound 1e14', 'ok|' + Format(Count))
        else
            Observer.ObserveError('biginteger bound 1e14');
        Big := 3;
        if TryForBig(Big, Count) then
            Observer.Observe('biginteger bound 3', 'ok|' + Format(Count))
        else
            Observer.ObserveError('biginteger bound 3');
        Dec := 2.5;
        R := '';
        for Count := 1 to Dec do
            R += Format(Count) + ',';
        Observer.Observe('decimal bound 2.5', R + '|' + Format(Count));
        Dec := 2.6;
        R := '';
        for Count := 1 to Dec do
            R += Format(Count) + ',';
        Observer.Observe('decimal bound 2.6', R + '|' + Format(Count));
        Dec := 0.5;
        R := '';
        for Count := Dec to 2 do
            R += Format(Count) + ',';
        Observer.Observe('decimal start 0.5', R + '|' + Format(Count));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryForBig(Big: BigInteger; var Count: Integer)
    var
        Turns: Integer;
    begin
        for Count := 1 to Big do begin
            Turns += 1;
            if Turns >= 5 then
                exit;
        end;
    end;
}
