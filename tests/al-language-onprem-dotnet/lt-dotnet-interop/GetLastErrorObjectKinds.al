// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope, but ONLY for a Target = OnPrem app, AL compiler 18.0 or newer (see GetLastErrorObject.al and TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; Base Application codeunit "DotNet Exception Handler" (1291); self-contained codeunits 61480-61484
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: after an error caught by Codeunit.Run: the class (GetType().FullName), Message, GetLastErrorCode, InnerException null or not, and GetBaseException() class and Message, for
//   Error(Label), Error(Text variable), Error(ErrorInfo), a failing TestField, Modify and Delete of a row that does not exist and an Evaluate without a return value;
//   GetLastErrorObject in a new session where no error has happened (StartSession); Type.Equals for two exceptions of the same and of different kinds; the lines of ToString of a dialog exception;
//   what "DotNet Exception Handler".Rethrow raises after each kind. Corpus issue 577.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtLekExc) { }
        type("System.Type"; LtLekType) { }
    }
}

codeunit 61480 "LT LEK Thrower"
{
    var
        Mode: Integer;
        MessageLabel: Label 'LT label error %1', Locked = true;

    trigger OnRun()
    var
        Entry: Record "Probe Observer Entry";
        Info: ErrorInfo;
        Text1: Text;
        Number: Integer;
        Zero: Integer;
        Result: Integer;
    begin
        case Mode of
            1:
                Error(MessageLabel, 'arg');
            2:
                begin
                    Text1 := 'LT text variable error';
                    Error(Text1);
                end;
            3:
                begin
                    Info := ErrorInfo.Create('LT errorinfo message');
                    Error(Info);
                end;
            4:
                begin
                    Entry."Entry No." := 0;
                    Entry.TestField("Entry No.", 5);
                end;
            5:
                begin
                    Entry."Entry No." := -987654;
                    Entry.Modify();
                end;
            6:
                begin
                    Entry."Entry No." := -987654;
                    Entry.Delete();
                end;
            7:
                Evaluate(Number, 'not a number');
            8:
                Error('LT plain literal');
            9:
                Result := 1 div Zero;
            10:
                Entry.TestField("Entry No.");
            11:
                Error('LT second literal');
        end;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 61481 "LT LEK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Thrower: Codeunit "LT LEK Thrower";
        Exc: DotNet LtLekExc;
        Base: DotNet LtLekExc;
        TypeOfExc: DotNet LtLekType;
        Ran: Boolean;
    begin
        Thrower.SetMode(Mode);
        Ran := Thrower.Run();
        Observer.Observe('ran', Format(Ran));
        Observer.Observe('lastErrorText', GetLastErrorText());
        Observer.Observe('lastErrorCode', GetLastErrorCode());
        Exc := GetLastErrorObject();
        Observer.Observe('isNull', Format(IsNull(Exc)));
        if IsNull(Exc) then
            exit;
        TypeOfExc := Exc.GetType();
        Observer.Observe('typeFullName', TypeOfExc.FullName);
        Observer.Observe('message', Exc.Message);
        Observer.Observe('innerExceptionIsNull', Format(IsNull(Exc.InnerException)));
        Base := Exc.GetBaseException();
        Observer.Observe('baseIsNull', Format(IsNull(Base)));
        if IsNull(Base) then
            exit;
        TypeOfExc := Base.GetType();
        Observer.Observe('baseTypeFullName', TypeOfExc.FullName);
        Observer.Observe('baseMessage', Base.Message);
    end;

    [Test]
    procedure Kind_ErrorWithLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_ErrorWithTextVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_ErrorWithErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_FailingTestFieldWithValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(4, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_FailingTestFieldWithoutValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(10, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_ModifyOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(5, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_DeleteOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(6, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_EvaluateWithoutReturnValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(7, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_ErrorWithLiteral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(8, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Kind_DivisionByZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(9, Observer);
        Observer.Finish();
    end;
}

// Runs in a session of its own (StartSession): that session has not had an error yet.
codeunit 61482 "LT LEK Fresh Session"
{
    trigger OnRun()
    var
        Exc: DotNet LtLekExc;
        Result: Text;
    begin
        Exc := GetLastErrorObject();
        Result := 'isNull=' + Format(IsNull(Exc)) + ';format=' + Format(Exc) + ';lastErrorText=[' + GetLastErrorText() + '];lastErrorCode=[' + GetLastErrorCode() + ']';
        IsolatedStorage.Set('LT_LEK_Fresh', Result, DataScope::Module);
    end;
}

codeunit 61483 "LT LEK Member Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fail(Mode: Integer): Boolean
    var
        Thrower: Codeunit "LT LEK Thrower";
    begin
        Thrower.SetMode(Mode);
        exit(Thrower.Run());
    end;

    local procedure SameType(A: DotNet LtLekExc; B: DotNet LtLekExc): Text
    var
        TypeA: DotNet LtLekType;
        TypeB: DotNet LtLekType;
    begin
        TypeA := A.GetType();
        TypeB := B.GetType();
        exit(Format(TypeA.Equals(TypeB)));
    end;

    [Test]
    procedure Session_GetLastErrorObjectBeforeAnyError()
    var
        Observer: Codeunit "Probe Observer";
        SessionId: Integer;
        Result: Text;
        Waited: Integer;
    begin
        if IsolatedStorage.Contains('LT_LEK_Fresh', DataScope::Module) then
            IsolatedStorage.Delete('LT_LEK_Fresh', DataScope::Module);
        Observer.Observe('started', Format(StartSession(SessionId, Codeunit::"LT LEK Fresh Session")));
        while (not IsolatedStorage.Contains('LT_LEK_Fresh', DataScope::Module)) and (Waited < 100) do begin
            Sleep(300);
            Waited += 1;
        end;
        if IsolatedStorage.Get('LT_LEK_Fresh', DataScope::Module, Result) then
            Observer.Observe('result', Result)
        else
            Observer.Observe('result', 'no answer from the session');
        if IsolatedStorage.Contains('LT_LEK_Fresh', DataScope::Module) then
            IsolatedStorage.Delete('LT_LEK_Fresh', DataScope::Module);
        Observer.Finish();
    end;

    [Test]
    procedure Type_Equals_SameKinds()
    var
        Observer: Codeunit "Probe Observer";
        First: DotNet LtLekExc;
        Second: DotNet LtLekExc;
    begin
        Fail(8);
        First := GetLastErrorObject();
        Fail(11);
        Second := GetLastErrorObject();
        Observer.Observe('dialog_dialog', SameType(First, Second));
        Observer.Observe('dialog_dialog_messagesDiffer', Format(First.Message <> Second.Message));
        Observer.Observe('dialog_dialog_sameObject', Format(First.Equals(Second)));
        Observer.Observe('dialog_self_sameObject', Format(First.Equals(First)));
        Fail(5);
        First := GetLastErrorObject();
        Fail(6);
        Second := GetLastErrorObject();
        Observer.Observe('notFound_notFound', SameType(First, Second));
        Observer.Finish();
    end;

    [Test]
    procedure Type_Equals_DifferentKinds()
    var
        Observer: Codeunit "Probe Observer";
        Dialog: DotNet LtLekExc;
        NotFound: DotNet LtLekExc;
        Division: DotNet LtLekExc;
    begin
        Fail(8);
        Dialog := GetLastErrorObject();
        Fail(5);
        NotFound := GetLastErrorObject();
        Fail(9);
        Division := GetLastErrorObject();
        Observer.Observe('dialog_notFound', SameType(Dialog, NotFound));
        Observer.Observe('dialog_division', SameType(Dialog, Division));
        Observer.Observe('notFound_division', SameType(NotFound, Division));
        Observer.Finish();
    end;

    [Test]
    procedure ToString_DialogException_Lines()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtLekExc;
        Lines: List of [Text];
        Lf: Text[1];
        Text1: Text;
        Index: Integer;
    begin
        Fail(8);
        Exc := GetLastErrorObject();
        Lf[1] := 10;
        Text1 := Exc.ToString();
        Lines := Text1.Split(Lf);
        Observer.Observe('lineCount', Format(Lines.Count()));
        Observer.Observe('endsWithLineFeed', Format(Text1.EndsWith(Lf)));
        for Index := 1 to Lines.Count() do
            if Index <= 12 then
                Observer.Observe('line' + Format(Index), Lines.Get(Index));
        Observer.Finish();
    end;
}

codeunit 61484 "LT LEK Rethrow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AfterError(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Thrower: Codeunit "LT LEK Thrower";
        Handler: Codeunit "DotNet Exception Handler";
        Exc: DotNet LtLekExc;
        TypeOfExc: DotNet LtLekType;
    begin
        Thrower.SetMode(Mode);
        Observer.Observe('ran', Format(Thrower.Run()));
        Observer.Observe('lastErrorText', GetLastErrorText());
        Handler.Collect();
        Observer.Observe('handlerMessage', Handler.GetMessage());
        Exc := GetLastErrorObject();
        TypeOfExc := Exc.GetType();
        Observer.Observe('tryCastToOwnType', Format(Handler.TryCastToType(TypeOfExc)));
        ClearLastError();
        asserterror Handler.Rethrow();
        Observer.Observe('rethrowText', GetLastErrorText());
        Observer.Observe('rethrowCode', GetLastErrorCode());
        Exc := GetLastErrorObject();
        TypeOfExc := Exc.GetType();
        Observer.Observe('rethrowType', TypeOfExc.FullName);
        Observer.Observe('rethrowInnerIsNull', Format(IsNull(Exc.InnerException)));
    end;

    [Test]
    procedure Rethrow_AfterErrorWithLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterErrorWithTextVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterErrorWithErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterFailingTestField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(4, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterModifyOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(5, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterDeleteOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(6, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterEvaluateWithoutReturnValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(7, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Rethrow_AfterDivisionByZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(9, Observer);
        Observer.Finish();
    end;
}
