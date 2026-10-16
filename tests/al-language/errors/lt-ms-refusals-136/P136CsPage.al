// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74335 and codeunit 74337 of P136CsBase.al; page 74341, codeunit 74342
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read inside page triggers (OnInit, OnNewRecord, OnAfterGetRecord, OnAfterGetCurrRecord, OnInsertRecord, OnModifyRecord, OnQueryClosePage, OnClosePage, an action) that a TestPage causes, and the table triggers and event subscribers those page operations raise
// BC versions: 29 (27 and 28 by CI)

page 74341 "LT P136 CS Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P136 CS Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Name; Rec.Name)
            {
                trigger OnValidate()
                var
                    Log: Codeunit "LT P136 CS Log";
                begin
                    Log.Capture('pgNameValidate');
                end;
            }
            field(Note; Rec.Note) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CaptureAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT P136 CS Log";
                begin
                    Log.Capture('pgAction');
                end;
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnOpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnNewRecord');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnAfterGetRecord');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnAfterGetCurrRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnModifyRecord');
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P136 CS Log";
    begin
        Log.Capture('pgOnClosePage');
    end;
}

codeunit 74342 "LT P136 CS Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P136 CS Log";

    local procedure Clean()
    var
        Row: Record "LT P136 CS Row";
    begin
        Row.DeleteAll();
        Log.Reset();
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; KeyName: Text)
    begin
        Observer.Observe(KeyName, Log.Frames(KeyName));
    end;

    [Test]
    procedure P136_Callstack_PageNewRecordAndInsert()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P136 CS Card";
    begin
        Clean();
        Card.OpenNew();
        Show(Observer, 'pgOnInit');
        Show(Observer, 'pgOnOpenPage');
        Show(Observer, 'pgOnNewRecord');
        Show(Observer, 'pgOnAfterGetCurrRecord');
        Card.Id.SetValue(1);
        Card.Name.SetValue('a');
        Show(Observer, 'pgNameValidate');
        Show(Observer, 'subBeforeValidate');
        Show(Observer, 'tblNameValidate');
        Show(Observer, 'subAfterValidate');
        Card.Note.SetValue('n');
        Show(Observer, 'extNoteValidate');
        Card.CaptureAction.Invoke();
        Show(Observer, 'pgAction');
        Log.Reset();
        Card.Close();
        Show(Observer, 'pgOnQueryClosePage');
        Show(Observer, 'pgOnInsertRecord');
        Show(Observer, 'subBeforeInsert');
        Show(Observer, 'tblOnInsert');
        Show(Observer, 'subAfterInsert');
        Show(Observer, 'pgOnClosePage');
        Observer.Expect('pgOnInit', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnInit(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 6');
        Observer.Expect('pgOnOpenPage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnOpenPage(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 6');
        Observer.Expect('pgOnNewRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnNewRecord(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 6');
        Observer.Expect('pgOnAfterGetCurrRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnAfterGetCurrRecord(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 6');
        Observer.Expect('pgNameValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341)."Name - OnValidate"(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 12');
        Observer.Expect('subBeforeValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeValidate line 2 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 12');
        Observer.Expect('tblNameValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335)."Name - OnValidate"(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 12');
        Observer.Expect('subAfterValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterValidate line 2 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 12');
        Observer.Expect('extNoteValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row Ext"(TableExtension 74336)."Note - OnValidate"(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 17');
        Observer.Expect('pgAction', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341)."CaptureAction - OnAction"(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 19');
        Observer.Expect('pgOnQueryClosePage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnQueryClosePage(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 22');
        Observer.Expect('pgOnInsertRecord', 'not captured');
        Observer.Expect('subBeforeInsert', 'not captured');
        Observer.Expect('tblOnInsert', 'not captured');
        Observer.Expect('subAfterInsert', 'not captured');
        Observer.Expect('pgOnClosePage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnClosePage(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageNewRecordAndInsert line 22');
        Observer.Verify();
    end;





    [Test]
    procedure P136_Callstack_PageEditAndModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P136 CS Row";
        Card: TestPage "LT P136 CS Card";
    begin
        Clean();
        Row.Id := 1;
        Row.Name := 'a';
        Row.Insert(false);
        Card.OpenEdit();
        Show(Observer, 'pgOnInit');
        Show(Observer, 'pgOnOpenPage');
        Show(Observer, 'pgOnAfterGetRecord');
        Show(Observer, 'pgOnAfterGetCurrRecord');
        Log.Reset();
        Card.Name.SetValue('changed');
        Show(Observer, 'pgNameValidate');
        Show(Observer, 'pgOnAfterGetCurrRecord');
        Card.Close();
        Show(Observer, 'pgOnQueryClosePage');
        Show(Observer, 'pgOnModifyRecord');
        Show(Observer, 'subBeforeModify');
        Show(Observer, 'tblOnModify');
        Show(Observer, 'extOnModify');
        Show(Observer, 'subAfterModify');
        Show(Observer, 'pgOnClosePage');
        Observer.Expect('pgOnInit', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnInit(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 10');
        Observer.Expect('pgOnOpenPage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnOpenPage(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 10');
        Observer.Expect('pgOnAfterGetRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnAfterGetRecord(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 10');
        Observer.Expect('pgOnAfterGetCurrRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnAfterGetCurrRecord(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 10');
        Observer.Expect('pgNameValidate', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341)."Name - OnValidate"(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 16');
        Observer.Expect('pgOnAfterGetCurrRecord', 'not captured');
        Observer.Expect('pgOnQueryClosePage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnQueryClosePage(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Expect('pgOnModifyRecord', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnModifyRecord(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Expect('subBeforeModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubBeforeModify line 2 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Expect('tblOnModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row"(Table 74335).OnModify(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Expect('extOnModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Row Ext"(TableExtension 74336).OnModify(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Expect('subAfterModify', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Subs"(CodeUnit 74338).SubAfterModify line 2 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Expect('pgOnClosePage', '"LT P136 CS Log"(CodeUnit 74337).Capture line 5 < "LT P136 CS Card"(Page 74341).OnClosePage(Trigger) line 4 < "LT P136 CS Page Tests"(CodeUnit 74342).P136_Callstack_PageEditAndModify line 19');
        Observer.Verify();
    end;




}
