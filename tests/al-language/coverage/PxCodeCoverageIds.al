// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares codeunits 86163-86165; calls test procedures of codeunit 67334 "W6 Code Coverage Ids"
// Probe: writer PX, probes-needed "Platform tables and session facts": Code Coverage Test Lookup "Method ID" of procedures with different and
// equal signatures, in one codeunit and in two; Tests Run "Method ID" and "Test ID" in a second test codeunit and across recordings.
// Line numbers in lines_a/lines_b count from the first line of the object text (for the first object of the file, the file start).
// Rule seen (BC 29 local): a Test Lookup Method ID is the Method Id of the procedure's Trigger/Function row in Code Coverage; equal for the same
// name and signature in two codeunits (NoArgs), different for different names with one signature. Tests Run rows have their own Method ID and
// Test ID per test procedure. A new CodeCoverageLog(true, ...) without clearing keeps only the rows of the new recording.
// BC versions: 27, 28, 29

codeunit 86164 "LT PX CC Target A"
{
    procedure NoArgs()
    begin
    end;

    procedure IntArg(X: Integer)
    begin
        if X = 0 then
            exit;
    end;

    procedure TextArgReturns(T: Text): Integer
    begin
        exit(StrLen(T));
    end;

    procedure SameSigOne()
    begin
    end;

    procedure SameSigTwo()
    begin
    end;
}

codeunit 86165 "LT PX CC Target B"
{
    procedure NoArgs()
    begin
    end;
}

// Writer QH (2026-10-21), al-runtime-rs PR 384 "needs probe": the Method ID of overloads, parameter kinds (var, Record subtype, List, Code
// and Text lengths), return types, casing, parameter names, access modifiers, events and triggers. Objects 86780-86782, 86785-86786.
table 86785 "LT QH CC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            begin
                Id := Id;
            end;
        }
        field(3; "Two Words"; Integer)
        {
            trigger OnValidate()
            begin
                Id := Id;
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Id := Id;
    end;
}

table 86786 "LT QH CC Row2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            begin
                Id := Id;
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Id := Id;
    end;
}

codeunit 86780 "LT QH CC Ovl"
{
    trigger OnRun()
    begin
    end;

    procedure Ovl()
    begin
    end;

    procedure Ovl(X: Integer)
    begin
    end;

    procedure Ovl(T: Text)
    begin
    end;

    procedure Ovl(X: Integer; Y: Integer)
    begin
    end;

    procedure Ovl(R: Record "LT QH CC Row")
    begin
    end;

    procedure RetInt(): Integer
    begin
        exit(1);
    end;

    procedure RetNamed() Result: Integer
    begin
        Result := 1;
    end;

    procedure RetText(): Text
    begin
        exit('');
    end;

    local procedure LocalProc()
    begin
    end;

    internal procedure InternalProc()
    begin
    end;

    procedure CodeParam(C: Code[10])
    begin
    end;

    procedure TextLenParam(T: Text[30])
    begin
    end;

    procedure ListParam(L: List of [Integer])
    begin
    end;

    procedure ListParamText(L: List of [Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnQhEvent(R: Record "LT QH CC Row")
    begin
    end;

    procedure CallAll()
    var
        R: Record "LT QH CC Row";
        L: List of [Integer];
        LT: List of [Text];
    begin
        Ovl();
        Ovl(1);
        Ovl('a');
        Ovl(1, 2);
        Ovl(R);
        if RetInt() = RetNamed() then;
        if RetText() = '' then;
        LocalProc();
        InternalProc();
        CodeParam('A');
        TextLenParam('A');
        ListParam(L);
        ListParamText(LT);
        OnQhEvent(R);
    end;
}

codeunit 86781 "LT QH CC Twin"
{
    trigger OnRun()
    begin
    end;

    procedure OVL()
    begin
    end;

    procedure Ovl(Y: Integer)
    begin
    end;

    procedure Ovl(R: Record "LT QH CC Row")
    begin
    end;

    procedure RetInt(): Integer
    begin
        exit(2);
    end;

    procedure CallAll()
    var
        R: Record "LT QH CC Row";
    begin
        OVL();
        Ovl(1);
        Ovl(R);
        if RetInt() = 0 then;
    end;
}

codeunit 86782 "LT QH CC Third"
{
    procedure Ovl(var X: Integer)
    begin
    end;

    procedure Ovl(R: Record "LT QH CC Row2")
    begin
    end;

    procedure RetInt(): Decimal
    begin
        exit(1);
    end;

    procedure CodeParam(C: Code[20])
    begin
    end;

    procedure TextLenParam(T: Text)
    begin
    end;

    procedure CallAll()
    var
        R: Record "LT QH CC Row2";
        X: Integer;
    begin
        Ovl(X);
        Ovl(R);
        if RetInt() = 0 then;
        CodeParam('A');
        TextLenParam('A');
    end;
}

codeunit 86783 "LT QH CC Empty A"
{
    var
        Counter: Integer;

    procedure E1()
    begin
    end;

    procedure E2()
    begin
    end;

    procedure C1()
    begin
        Counter += 1;
        E2();
    end;
}

codeunit 86784 "LT QH CC Empty B"
{
    var
        Counter: Integer;

    procedure E1()
    begin
    end;

    procedure E2()
    begin
    end;

    procedure C1()
    begin
        Counter += 1;
        E1();
    end;
}

codeunit 86163 "LT PX Code Coverage Ids"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        CodeCoverage: Record "Code Coverage";
        TestLookup: Record "Code Coverage Test Lookup";
        TestsRun: Record "Code Coverage Tests Run";
    begin
        CodeCoverageLog(false, false);
        CodeCoverageLog(false, true);
        CodeCoverage.DeleteAll();
        TestLookup.DeleteAll();
        TestsRun.DeleteAll();
    end;

    // helper tests: each calls one target procedure while a recording test runs them; they observe nothing.
    [Test]
    procedure PxRunsANoArgs()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.NoArgs();
    end;

    [Test]
    procedure PxRunsAIntArg()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.IntArg(1);
    end;

    [Test]
    procedure PxRunsATextArg()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        if A.TextArgReturns('ab') = 0 then
            Error('unreachable');
    end;

    [Test]
    procedure PxRunsASameOne()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.SameSigOne();
    end;

    [Test]
    procedure PxRunsASameTwo()
    var
        A: Codeunit "LT PX CC Target A";
    begin
        A.SameSigTwo();
    end;

    [Test]
    procedure PxRunsBNoArgs()
    var
        B: Codeunit "LT PX CC Target B";
    begin
        B.NoArgs();
    end;

    // Rows in the order of Names (Tests Run is keyed by its Test ID, a number that changes from run to run, so neither the Test ID nor
    // the row order is asserted). The Test Lookup rows of a run are found through its Test ID. testids_distinct: every row has its own one.
    local procedure DumpRuns(Names: Text): Text
    var
        TestsRun: Record "Code Coverage Tests Run";
        TestLookup: Record "Code Coverage Test Lookup";
        Seen: List of [Integer];
        Name: Text;
        Result: Text;
        Distinct: Boolean;
    begin
        Distinct := true;
        foreach Name in Names.Split(',') do begin
            // A SetRange on "Method Name" is not applied by this platform table (seen on BC 29 local), so the rows are matched in AL.
            if TestsRun.FindSet() then
                repeat
                    if TestsRun."Method Name" <> Name then
                        continue;
                    if Seen.Contains(TestsRun."Test ID") then
                        Distinct := false;
                    Seen.Add(TestsRun."Test ID");
                    Result += StrSubstNo('[%1 obj=%2 methodid=%3:', TestsRun."Method Name", TestsRun."Object ID", TestsRun."Method ID");
                    TestLookup.SetRange("Test ID", TestsRun."Test ID");
                    if TestLookup.FindSet() then
                        repeat
                            Result += StrSubstNo(' %1 %2 %3', TestLookup."Object Type", TestLookup."Object ID", TestLookup."Method ID");
                        until TestLookup.Next() = 0;
                    Result += '] ';
                until TestsRun.Next() = 0;
        end;
        exit(Result + StrSubstNo('rows=%1 testids_distinct=%2', TestsRun.Count(), Distinct));
    end;

    local procedure DumpLookups(): Text
    var
        TestLookup: Record "Code Coverage Test Lookup";
    begin
        exit('count=' + Format(TestLookup.Count()));
    end;

    local procedure DumpLineMethodIds(ObjectId: Integer): Text
    var
        CodeCoverage: Record "Code Coverage";
        Result: Text;
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", ObjectId);
        if CodeCoverage.FindSet() then
            repeat
                Result += StrSubstNo('L%1:%2/%3 ', CodeCoverage."Line No.", CodeCoverage."Line Type", CodeCoverage."Method Id");
            until CodeCoverage.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure PX_MethodIds_OfSixProcedures_TwoCodeunits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        PxRunsANoArgs();
        PxRunsAIntArg();
        PxRunsATextArg();
        PxRunsASameOne();
        PxRunsASameTwo();
        PxRunsBNoArgs();
        CodeCoverageLog(false, false);
        Observer.Observe('runs', DumpRuns('PxRunsANoArgs,PxRunsAIntArg,PxRunsATextArg,PxRunsASameOne,PxRunsASameTwo,PxRunsBNoArgs'));
        Observer.Observe('lookups', DumpLookups());
        Observer.Observe('lines_a', DumpLineMethodIds(Codeunit::"LT PX CC Target A"));
        Observer.Observe('lines_b', DumpLineMethodIds(Codeunit::"LT PX CC Target B"));
        Initialize();
        Observer.Expect('runs', '[PxRunsANoArgs obj=86163 methodid=1797822318: Codeunit 86164 1569086646] [PxRunsAIntArg obj=86163 methodid=-133430896: Codeunit 86164 -370288627] [PxRunsATextArg obj=86163 methodid=-652159326: Codeunit 86164 -1663764975] [PxRunsASameOne obj=86163 methodid=-1803411697: Codeunit 86164 -130816186] [PxRunsASameTwo obj=86163 methodid=-450565804: Codeunit 86164 -1760197669] [PxRunsBNoArgs obj=86163 methodid=667973114: Codeunit 86165 1569086646] rows=6 testids_distinct=Yes');
        Observer.Expect('lookups', 'count=6');
        Observer.Expect('lines_a', 'L0:Object/-1 L14:Trigger/Function/1569086646 L15:Empty/-1 L16:Empty/-1 L18:Trigger/Function/-370288627 L19:Empty/-1 L20:Code/-370288627 L21:Code/-370288627 L22:Empty/-1 L24:Trigger/Function/-1663764975 L25:Empty/-1 L26:Code/-1663764975 L27:Empty/-1 L29:Trigger/Function/-130816186 L30:Empty/-1 L31:Empty/-1 L33:Trigger/Function/-1760197669 L34:Empty/-1 L35:Empty/-1 ');
        Observer.Expect('lines_b', 'L0:Object/-1 L4:Trigger/Function/1569086646 L5:Empty/-1 L6:Empty/-1 ');
        Observer.Verify();
    end;

    [Test]
    procedure PX_TestIds_TwoRecordings_AndAnotherTestCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        W6: Codeunit "W6 Code Coverage Ids";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        PxRunsANoArgs();
        W6.MethodA();
        CodeCoverageLog(false, false);
        Observer.Observe('first', DumpRuns('MethodA,PxRunsANoArgs,PxRunsBNoArgs'));
        CodeCoverageLog(true, false);
        PxRunsBNoArgs();
        CodeCoverageLog(false, false);
        Observer.Observe('second_without_reset', DumpRuns('MethodA,PxRunsANoArgs,PxRunsBNoArgs'));
        Initialize();
        Observer.Expect('first', '[MethodA obj=67334 methodid=915199647:] [PxRunsANoArgs obj=86163 methodid=1797822318: Codeunit 86164 1569086646] rows=2 testids_distinct=Yes');
        Observer.Expect('second_without_reset', '[PxRunsBNoArgs obj=86163 methodid=667973114: Codeunit 86165 1569086646] rows=1 testids_distinct=Yes');
        Observer.Verify();
    end;

    // Writer QH (2026-10-21): the Trigger/Function rows of the QH targets, as L<line>=<Method Id>.
    local procedure QhFunctionRows(ObjectType: Option; ObjectId: Integer): Text
    var
        CodeCoverage: Record "Code Coverage";
        Result: Text;
    begin
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectId);
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::"Trigger/Function");
        if CodeCoverage.FindSet() then
            repeat
                Result += StrSubstNo('L%1=%2/h%3 ', CodeCoverage."Line No.", CodeCoverage."Method Id", CodeCoverage."No. of Hits");
            until CodeCoverage.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure QH_MethodIds_Overloads_ParameterKinds_Codeunits()
    var
        Observer: Codeunit "Probe Observer";
        CodeCoverage: Record "Code Coverage";
        Ovl: Codeunit "LT QH CC Ovl";
        Twin: Codeunit "LT QH CC Twin";
        Third: Codeunit "LT QH CC Third";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Ovl.CallAll();
        Twin.CallAll();
        Third.CallAll();
        Codeunit.Run(Codeunit::"LT QH CC Ovl");
        Codeunit.Run(Codeunit::"LT QH CC Twin");
        CodeCoverageLog(false, false);
        Observer.Observe('ovl', QhFunctionRows(CodeCoverage."Object Type"::Codeunit, Codeunit::"LT QH CC Ovl"));
        Observer.Observe('twin', QhFunctionRows(CodeCoverage."Object Type"::Codeunit, Codeunit::"LT QH CC Twin"));
        Observer.Observe('third', QhFunctionRows(CodeCoverage."Object Type"::Codeunit, Codeunit::"LT QH CC Third"));
        Initialize();
        Observer.Finish();
    end;

    [Test]
    procedure QH_MethodIds_TableAndFieldTriggers()
    var
        Observer: Codeunit "Probe Observer";
        CodeCoverage: Record "Code Coverage";
        Row: Record "LT QH CC Row";
        Row2: Record "LT QH CC Row2";
    begin
        Initialize();
        Row.DeleteAll();
        Row2.DeleteAll();
        CodeCoverageLog(true, false);
        Row.Id := 1;
        Row.Validate(Name, 'a');
        Row.Validate("Two Words", 2);
        Row.Insert(true);
        Row2.Id := 1;
        Row2.Validate(Name, 'a');
        Row2.Insert(true);
        CodeCoverageLog(false, false);
        Observer.Observe('row', QhFunctionRows(CodeCoverage."Object Type"::Table, Database::"LT QH CC Row"));
        Observer.Observe('row2', QhFunctionRows(CodeCoverage."Object Type"::Table, Database::"LT QH CC Row2"));
        Initialize();
        Row.DeleteAll();
        Row2.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure QH_MethodIds_EmptyBodies_CalledFromTheTest()
    var
        Observer: Codeunit "Probe Observer";
        CodeCoverage: Record "Code Coverage";
        R: Record "LT QH CC Row";
        R2: Record "LT QH CC Row2";
        Ovl: Codeunit "LT QH CC Ovl";
        Twin: Codeunit "LT QH CC Twin";
        Third: Codeunit "LT QH CC Third";
        L: List of [Integer];
        LT: List of [Text];
        X: Integer;
    begin
        Initialize();
        CodeCoverageLog(true, false);
        Ovl.Ovl();
        Ovl.Ovl(1);
        Ovl.Ovl('a');
        Ovl.Ovl(1, 2);
        Ovl.Ovl(R);
        Ovl.CodeParam('A');
        Ovl.TextLenParam('A');
        Ovl.ListParam(L);
        Ovl.ListParamText(LT);
        Ovl.InternalProc();
        Ovl.OnQhEvent(R);
        Twin.OVL();
        Twin.Ovl(1);
        Twin.Ovl(R);
        Third.Ovl(X);
        Third.Ovl(R2);
        Third.CodeParam('A');
        Third.TextLenParam('A');
        CodeCoverageLog(false, false);
        Observer.Observe('ovl', QhFunctionRows(CodeCoverage."Object Type"::Codeunit, Codeunit::"LT QH CC Ovl"));
        Observer.Observe('twin', QhFunctionRows(CodeCoverage."Object Type"::Codeunit, Codeunit::"LT QH CC Twin"));
        Observer.Observe('third', QhFunctionRows(CodeCoverage."Object Type"::Codeunit, Codeunit::"LT QH CC Third"));
        Initialize();
        Observer.Finish();
    end;

    // Each of the two Empty codeunits is used by this one test only, so it is loaded for the first time while the recording runs.
    local procedure QhAllRows(ObjectId: Integer): Text
    var
        CodeCoverage: Record "Code Coverage";
        Result: Text;
    begin
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Codeunit);
        CodeCoverage.SetRange("Object ID", ObjectId);
        if CodeCoverage.FindSet() then
            repeat
                Result += StrSubstNo('L%1:%2=%3/h%4 ', CodeCoverage."Line No.", CodeCoverage."Line Type", CodeCoverage."Method Id", CodeCoverage."No. of Hits");
            until CodeCoverage.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure QH_MethodIds_EmptyProcedure_CalledFromOutside_OrInside()
    var
        Observer: Codeunit "Probe Observer";
        A: Codeunit "LT QH CC Empty A";
        B: Codeunit "LT QH CC Empty B";
    begin
        Initialize();
        CodeCoverageLog(true, false);
        A.E1();
        CodeCoverageLog(false, false);
        Observer.Observe('a_after_e1', QhAllRows(Codeunit::"LT QH CC Empty A"));
        CodeCoverageLog(true, false);
        A.C1();
        CodeCoverageLog(false, false);
        Observer.Observe('a_after_c1', QhAllRows(Codeunit::"LT QH CC Empty A"));
        CodeCoverageLog(true, false);
        B.C1();
        CodeCoverageLog(false, false);
        Observer.Observe('b_after_c1', QhAllRows(Codeunit::"LT QH CC Empty B"));
        Initialize();
        Observer.Finish();
    end;
}
