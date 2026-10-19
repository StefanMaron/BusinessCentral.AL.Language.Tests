// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 86260..86263 (DiFwTables.al)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: writing a value into a FlowField (corpus issue #665): assignment then Modify/Get/CalcFields, assignment then Insert, Validate,
// Modify(true) when only a FlowField changed (OnModify, xRec, SystemRowVersion, SystemModifiedAt),
// RecordRef/FieldRef Value, Validate and Modify, TransferFields and record assignment, Init/Clear/Reset/Find/Next/Get, SetAutoCalcFields,
// temporary records, Exist (Boolean) and Lookup (Text) FlowFields, assignment to a FlowFilter field, CalcFields after an assignment.
// Every test also reads the CalcFormula source table (LT DI FW Child) and the trigger log before and after the write ('src' and 'log').
// A call that may raise runs as `asserterror begin <call>; Error(NoErrorTok); end;` so both outcomes are observed; when it did not raise,
// the call runs again outside asserterror (asserterror rolls the database back).
// BC versions: 27, 28, 29

codeunit 86264 "LT DI FW Write Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NoErrorTok: Label 'DI-NO-ERROR', Locked = true;

    local procedure Seed()
    var
        Parent: Record "LT DI FW Parent";
        Child: Record "LT DI FW Child";
        LogRow: Record "LT DI FW Log";
        CopyRow: Record "LT DI FW Copy";
    begin
        Parent.DeleteAll(false);
        Child.DeleteAll(false);
        LogRow.DeleteAll(false);
        CopyRow.DeleteAll(false);
        AddParent(1, 'P1');
        AddParent(2, 'P2');
        AddParent(3, 'P3');
        AddChild(1, 1, 'A', 10, 20260110D);
        AddChild(2, 1, 'B', 20, 20260210D);
        AddChild(3, 1, 'C', 30, 20260310D);
        AddChild(4, 3, 'D', 5, 20260115D);
        LogRow.DeleteAll(false);
    end;

    local procedure AddParent(No: Integer; NewName: Text[30])
    var
        Parent: Record "LT DI FW Parent";
    begin
        Parent.Init();
        Parent."No." := No;
        Parent.Name := NewName;
        Parent.Insert(false);
    end;

    local procedure AddChild(EntryNo: Integer; ParentNo: Integer; NewCode: Text[30]; NewAmount: Decimal; PostingDate: Date)
    var
        Child: Record "LT DI FW Child";
    begin
        Child.Init();
        Child."Entry No." := EntryNo;
        Child."Parent No." := ParentNo;
        Child.Code := NewCode;
        Child.Amount := NewAmount;
        Child."Posting Date" := PostingDate;
        Child.Insert(false);
    end;

    // The CalcFormula source table: row count, then every row as entry|parent|code|amount|date.
    local procedure Src(): Text
    var
        Child: Record "LT DI FW Child";
        Result: Text;
    begin
        Result := 'n=' + Format(Child.Count());
        if Child.FindSet() then
            repeat
                Result += ';' + Format(Child."Entry No.") + '|' + Format(Child."Parent No.") + '|' + Child.Code + '|' + Format(Child.Amount, 0, 9) + '|' + Format(Child."Posting Date", 0, 9);
            until Child.Next() = 0;
        exit(Result);
    end;

    // The stored parent rows: no|name for every row.
    local procedure Parents(): Text
    var
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Result := 'n=' + Format(Parent.Count());
        if Parent.FindSet() then
            repeat
                Result += ';' + Format(Parent."No.") + '|' + Parent.Name;
            until Parent.Next() = 0;
        exit(Result);
    end;

    // The trigger log since the last call (then emptied).
    local procedure TakeLog(): Text
    var
        LogRow: Record "LT DI FW Log";
        Result: Text;
    begin
        Result := 'n=' + Format(LogRow.Count());
        if LogRow.FindSet() then
            repeat
                Result += ';' + LogRow.Msg;
            until LogRow.Next() = 0;
        LogRow.DeleteAll(false);
        exit(Result);
    end;

    local procedure Outcome(): Text
    begin
        if GetLastErrorText() = NoErrorTok then begin
            ClearLastError();
            exit('ok');
        end;
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure StoredCount(No: Integer): Text
    var
        Parent: Record "LT DI FW Parent";
    begin
        Parent.Get(No);
        exit(Format(Parent."Child Count"));
    end;

    local procedure CalcCount(No: Integer): Text
    var
        Parent: Record "LT DI FW Parent";
    begin
        Parent.Get(No);
        Parent.CalcFields("Child Count");
        exit(Format(Parent."Child Count"));
    end;

    // ---- item 1: assignment to a FlowField on a row that has children, then Modify, Get and CalcFields ----
    [Test]
    procedure DI_AssignThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Other: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Observer.Observe('src before', Src());
        Parent.Get(1);
        Observer.Observe('after Get', Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent."Child Amount" := 99;
        Observer.Observe('read at once', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        asserterror begin
            Parent.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify()', Result);
        if Result = 'ok' then
            Parent.Modify();
        Observer.Observe('after Modify', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Other.Get(1);
        Observer.Observe('other var Get', Format(Other."Child Count") + '/' + Format(Other."Child Amount"));
        Parent.Get(1);
        Observer.Observe('same var Get', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Parent."Child Count" := 7;
        Parent.CalcFields("Child Count", "Child Amount");
        Observer.Observe('CalcFields', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Observe('log', TakeLog());
        Observer.Finish();
    end;

    // ---- item 2: assignment on a new record, then Insert, Get and CalcFields ----
    [Test]
    procedure DI_AssignThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Other: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        AddChild(5, 10, 'E', 1, 20260101D);
        Observer.Observe('src before', Src());
        Parent.Init();
        Parent."No." := 10;
        Parent.Name := 'P10';
        Parent."Child Count" := 7;
        Parent."Child Amount" := 99;
        Parent."Has Children" := false;
        Parent."First Child Code" := 'ZZ';
        asserterror begin
            Parent.Insert(true);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Insert(true)', Result);
        if Result = 'ok' then
            Parent.Insert(true);
        Observer.Observe('after Insert', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount") + '/' + Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Observer.Observe('log', TakeLog());
        Other.Get(10);
        Observer.Observe('Get', Format(Other."Child Count") + '/' + Format(Other."Child Amount") + '/' + Format(Other."Has Children") + '/' + Other."First Child Code");
        Other.CalcFields("Child Count", "Child Amount", "Has Children", "First Child Code");
        Observer.Observe('CalcFields', Format(Other."Child Count") + '/' + Format(Other."Child Amount") + '/' + Format(Other."Has Children") + '/' + Other."First Child Code");
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Finish();
    end;

    // ---- item 3: Validate on a FlowField (Count with an OnValidate trigger, Sum without one) ----
    [Test]
    procedure DI_ValidateFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        asserterror begin
            Parent.Validate("Child Count", 7);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Validate count', Result);
        Observer.Observe('log in asserterror', TakeLog());
        Parent.Get(1);
        if Result = 'ok' then
            Parent.Validate("Child Count", 7);
        Observer.Observe('count after', Format(Parent."Child Count"));
        Observer.Observe('log', TakeLog());
        asserterror begin
            Parent.Validate("Child Amount", 99);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Validate amount', Result);
        if Result = 'ok' then
            Parent.Validate("Child Amount", 99);
        Observer.Observe('amount after', Format(Parent."Child Amount"));
        asserterror begin
            Parent.Modify(true);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify(true)', Result);
        if Result = 'ok' then
            Parent.Modify(true);
        Observer.Observe('log after modify', TakeLog());
        Observer.Observe('stored', StoredCount(1) + ' calc ' + CalcCount(1));
        Observer.Observe('src after', Src());
        Observer.Finish();
    end;

    // item 4 (ModifyAll on a FlowField) does not compile: AL0779, must-not-compile cases 1370 and 1888.

    local procedure Snap(var Versions: Dictionary of [Integer, BigInteger]; var Stamps: Dictionary of [Integer, DateTime])
    var
        Parent: Record "LT DI FW Parent";
    begin
        Clear(Versions);
        Clear(Stamps);
        if Parent.FindSet() then
            repeat
                Versions.Add(Parent."No.", Parent.SystemRowVersion);
                Stamps.Add(Parent."No.", Parent.SystemModifiedAt);
            until Parent.Next() = 0;
    end;

    // For every parent row: no:rowversion changed (yes/no), SystemModifiedAt changed (yes/no).
    local procedure ChangedRows(Versions: Dictionary of [Integer, BigInteger]; Stamps: Dictionary of [Integer, DateTime]): Text
    var
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        if Parent.FindSet() then
            repeat
                Result += Format(Parent."No.") + ':rv ' + Format(Parent.SystemRowVersion <> Versions.Get(Parent."No.")) + ' at ' + Format(Parent.SystemModifiedAt <> Stamps.Get(Parent."No.")) + ';';
            until Parent.Next() = 0;
        exit(Result);
    end;

    // ---- item 5: Modify(true) when only a FlowField was changed: OnModify, xRec, SystemRowVersion, SystemModifiedAt ----
    [Test]
    procedure DI_ModifyOnlyFlowFieldChanged()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Versions: Dictionary of [Integer, BigInteger];
        Stamps: Dictionary of [Integer, DateTime];
    begin
        Seed();
        // a: Get, assign, Modify(true)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Modify(true);
        Observer.Observe('a changed', ChangedRows(Versions, Stamps));
        Observer.Observe('a log', TakeLog());
        // b: Get, CalcFields, assign, Modify(true)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent.CalcFields("Child Count");
        Parent."Child Count" := 7;
        Parent.Modify(true);
        Observer.Observe('b changed', ChangedRows(Versions, Stamps));
        Observer.Observe('b log', TakeLog());
        // c: Get, nothing changed, Modify(true)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent.Modify(true);
        Observer.Observe('c changed', ChangedRows(Versions, Stamps));
        Observer.Observe('c log', TakeLog());
        // d: Get, assign, Modify(false)
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Modify(false);
        Observer.Observe('d changed', ChangedRows(Versions, Stamps));
        Observer.Observe('d log', TakeLog());
        Observer.Observe('src after', Src());
        Observer.Finish();
    end;

    // ---- item 6: RecordRef / FieldRef on a FlowField: Class, Value :=, Validate, RecRef.Modify ----
    [Test]
    procedure DI_FieldRefWrite()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        RecRef: RecordRef;
        FRef: FieldRef;
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        RecRef.GetTable(Parent);
        FRef := RecRef.Field(3);
        Observer.Observe('class', Format(FRef.Class()) + '/' + Format(RecRef.Field(4).Class()) + '/' + Format(RecRef.Field(7).Class()));
        Observer.Observe('value before', Format(FRef.Value()));
        asserterror begin
            FRef.Value := 7;
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Value :=', Result);
        if Result = 'ok' then
            FRef.Value := 7;
        Observer.Observe('value after', Format(FRef.Value()) + '/' + Format(RecRef.Field(3).Value()));
        asserterror begin
            RecRef.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('RecRef.Modify', Result);
        if Result = 'ok' then
            RecRef.Modify();
        Observer.Observe('value after modify', Format(RecRef.Field(3).Value()));
        Observer.Observe('stored', StoredCount(1) + ' calc ' + CalcCount(1));
        asserterror begin
            FRef.Validate(8);
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Validate(8)', Result);
        Observer.Observe('log in asserterror', TakeLog());
        if Result = 'ok' then
            FRef.Validate(8);
        Observer.Observe('value after validate', Format(FRef.Value()));
        Observer.Observe('log', TakeLog());
        FRef.CalcField();
        Observer.Observe('CalcField', Format(FRef.Value()));
        Observer.Observe('src after', Src());
        Observer.Finish();
    end;

    // ---- item 7: TransferFields and record assignment with an assigned and with a calculated FlowField ----
    [Test]
    procedure DI_TransferFieldsAndAssign()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT DI FW Parent";
        Target: Record "LT DI FW Parent";
        CopyRow: Record "LT DI FW Copy";
    begin
        Seed();
        // assigned value
        Source.Get(1);
        Source."Child Count" := 7;
        Target.Get(2);
        Target.TransferFields(Source);
        Observer.Observe('assigned TF', Format(Target."No.") + '/' + Format(Target."Child Count"));
        Clear(Target);
        Target.Init();
        Target.TransferFields(Source);
        Observer.Observe('assigned Init TF', Format(Target."No.") + '/' + Format(Target."Child Count"));
        Clear(Target);
        Target.Get(2);
        Target.TransferFields(Source, false);
        Observer.Observe('assigned TF false', Format(Target."No.") + '/' + Format(Target."Child Count"));
        Clear(Target);
        Target := Source;
        Observer.Observe('assigned :=', Format(Target."No.") + '/' + Format(Target."Child Count"));
        CopyRow.Init();
        CopyRow.TransferFields(Source);
        Observer.Observe('assigned to normal', Format(CopyRow."No.") + '/' + Format(CopyRow."Child Count"));
        // calculated value
        Source.Get(1);
        Source.CalcFields("Child Count", "Child Amount");
        Clear(Target);
        Target.Get(2);
        Target.TransferFields(Source);
        Observer.Observe('calc TF', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Clear(Target);
        Target.Init();
        Target.TransferFields(Source);
        Observer.Observe('calc Init TF', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Clear(Target);
        Target := Source;
        Observer.Observe('calc :=', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Clear(CopyRow);
        CopyRow.Init();
        CopyRow.TransferFields(Source);
        Observer.Observe('calc to normal', Format(CopyRow."No.") + '/' + Format(CopyRow."Child Count") + '/' + Format(CopyRow."Child Amount"));
        // normal field into a FlowField
        Clear(CopyRow);
        CopyRow."No." := 5;
        CopyRow."Child Count" := 9;
        CopyRow."Child Amount" := 4.5;
        Clear(Target);
        Target.TransferFields(CopyRow);
        Observer.Observe('normal to flow', Format(Target."No.") + '/' + Format(Target."Child Count") + '/' + Format(Target."Child Amount"));
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Finish();
    end;

    // ---- item 8: an assigned FlowField value after Init, Clear, Reset, Find, Next, Get and SetAutoCalcFields ----
    [Test]
    procedure DI_AssignedValueLifetime()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
    begin
        Seed();
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Init();
        Observer.Observe('Init', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Get(1);
        Parent."Child Count" := 7;
        Clear(Parent);
        Observer.Observe('Clear', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Reset();
        Observer.Observe('Reset', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.SetRange("No.", 1);
        Parent.Find('-');
        Observer.Observe('Find', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent.Reset();
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent.Next();
        Observer.Observe('Next', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Get(1);
        Observer.Observe('Get', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Get(3);
        Observer.Observe('Get other', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Clear(Parent);
        Parent.SetAutoCalcFields("Child Count");
        Parent.Get(1);
        Parent."Child Count" := 7;
        Observer.Observe('auto assigned', Format(Parent."Child Count"));
        Parent.Get(1);
        Observer.Observe('auto Get', Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.SetRange("No.", 1, 3);
        Parent.FindFirst();
        Observer.Observe('auto FindFirst', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Next();
        Observer.Observe('auto Next', Format(Parent."No.") + '/' + Format(Parent."Child Count"));
        Parent."Child Count" := 7;
        Parent.Modify();
        Observer.Observe('auto after Modify', Format(Parent."Child Count"));
        Observer.Observe('src after', Src());
        Observer.Finish();
    end;

    // ---- item 9: a temporary record: assignment, Modify, Get, CalcFields ----
    [Test]
    procedure DI_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempParent: Record "LT DI FW Parent" temporary;
    begin
        Seed();
        TempParent.Init();
        TempParent."No." := 1;
        TempParent."Child Count" := 5;
        TempParent.Insert();
        TempParent.Get(1);
        Observer.Observe('insert then Get', Format(TempParent."Child Count"));
        TempParent."Child Count" := 7;
        TempParent.Modify();
        Observer.Observe('after Modify', Format(TempParent."Child Count"));
        Clear(TempParent."Child Count");
        TempParent.Get(1);
        Observer.Observe('after Get', Format(TempParent."Child Count"));
        TempParent.FindFirst();
        Observer.Observe('after FindFirst', Format(TempParent."Child Count"));
        TempParent.CalcFields("Child Count");
        Observer.Observe('CalcFields', Format(TempParent."Child Count"));
        TempParent.Get(1);
        Observer.Observe('Get after CalcFields', Format(TempParent."Child Count"));
        TempParent.Init();
        TempParent."No." := 2;
        TempParent."Child Count" := 4;
        TempParent.Insert();
        TempParent.CalcFields("Child Count");
        Observer.Observe('row 2 CalcFields', Format(TempParent."Child Count"));
        Observer.Observe('log', TakeLog());
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Finish();
    end;

    // ---- item 10: Exist (Boolean) and Lookup (Text) FlowFields with an assigned value ----
    [Test]
    procedure DI_ExistAndLookupAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        Observer.Observe('Get', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent."Has Children" := false;
        Parent."First Child Code" := 'ZZ';
        Observer.Observe('read at once', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent.Get(2);
        Parent."Has Children" := true;
        Parent."First Child Code" := 'YY';
        Observer.Observe('row 2 assigned', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        asserterror begin
            Parent.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify()', Result);
        if Result = 'ok' then
            Parent.Modify();
        Observer.Observe('after Modify', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent.Get(2);
        Observer.Observe('after Get', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Parent."Has Children" := true;
        Parent."First Child Code" := 'YY';
        Parent.CalcFields("Has Children", "First Child Code");
        Observer.Observe('CalcFields', Format(Parent."Has Children") + '/' + Parent."First Child Code");
        Observer.Observe('src after', Src());
        Observer.Finish();
    end;

    // ---- item 11: assignment to a FlowFilter field, then Modify, Get and CalcFields ----
    [Test]
    procedure DI_FlowFilterAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Result: Text;
    begin
        Seed();
        Parent.Get(1);
        Parent.CalcFields("Child Amount");
        Observer.Observe('no filter', Format(Parent."Child Amount"));
        Parent."Date Filter" := 20260110D;
        Observer.Observe('read at once', Format(Parent."Date Filter", 0, 9) + ' getfilter=' + Parent.GetFilter("Date Filter"));
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields with assigned', Format(Parent."Child Amount"));
        asserterror begin
            Parent.Modify();
            Error(NoErrorTok);
        end;
        Result := Outcome();
        Observer.Observe('Modify()', Result);
        if Result = 'ok' then
            Parent.Modify();
        Observer.Observe('after Modify', Format(Parent."Date Filter", 0, 9));
        Parent.Get(1);
        Observer.Observe('after Get', Format(Parent."Date Filter", 0, 9));
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields after Get', Format(Parent."Child Amount"));
        Parent.SetRange("Date Filter", 20260110D);
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields with SetRange', Format(Parent."Child Amount") + ' field=' + Format(Parent."Date Filter", 0, 9));
        Observer.Observe('src after', Src());
        Observer.Observe('parents', Parents());
        Observer.Finish();
    end;

    // ---- item 13: CalcFields on a record whose FlowField was assigned, then Modify ----
    [Test]
    procedure DI_CalcFieldsAfterAssign()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT DI FW Parent";
        Versions: Dictionary of [Integer, BigInteger];
        Stamps: Dictionary of [Integer, DateTime];
    begin
        Seed();
        Parent.Get(1);
        Parent."Child Count" := 7;
        Parent."Child Amount" := 99;
        Parent.CalcFields("Child Count");
        Observer.Observe('CalcFields one', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Parent.CalcFields("Child Amount");
        Observer.Observe('CalcFields both', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Snap(Versions, Stamps);
        Sleep(30);
        Parent.Modify(true);
        Observer.Observe('changed', ChangedRows(Versions, Stamps));
        Observer.Observe('log', TakeLog());
        Observer.Observe('after Modify', Format(Parent."Child Count") + '/' + Format(Parent."Child Amount"));
        Observer.Observe('stored', StoredCount(1) + ' calc ' + CalcCount(1));
        Observer.Observe('src after', Src());
        Observer.Finish();
    end;
}
