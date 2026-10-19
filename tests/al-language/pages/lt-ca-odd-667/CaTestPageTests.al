// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 84100, log codeunit 84101, pages 84100-84103 (CaObjects.al)
// Settles corpus issue 667 (odd AL behavior leads, part B), items 1, 3, 6, 7, 9, 15 and 16.
// BC versions: 27, 28, 29
codeunit 84110 "LT CA TestPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(RowCode: Code[20]; RowName: Text[50]; RowAmt: Decimal; RowTxt: Text[30])
    var
        Row: Record "LT CA Row";
        Log: Codeunit "LT CA Log";
    begin
        Row.DeleteAll();
        Row."Code" := RowCode;
        Row.Name := RowName;
        Row.Amt := RowAmt;
        Row.Txt := RowTxt;
        Row.Insert();
        Log.Take();
    end;

    local procedure OpenCard(var P: TestPage "LT CA Card"; RowCode: Code[20])
    var
        Row: Record "LT CA Row";
    begin
        Row.Get(RowCode);
        P.OpenEdit();
        P.GoToRecord(Row);
    end;

    [TryFunction]
    local procedure TryAmtBlankDec(var P: TestPage "LT CA Card"; var D: Decimal)
    begin
        D := P.AmtBlankZero.AsDecimal();
    end;

    [TryFunction]
    local procedure TryAmtBlankInt(var P: TestPage "LT CA Card"; var I: Integer)
    begin
        I := P.AmtBlankZero.AsInteger();
    end;

    [TryFunction]
    local procedure TryTxtDec(var P: TestPage "LT CA Card"; var D: Decimal)
    begin
        D := P.TxtCtl.AsDecimal();
    end;

    // ---- item 1: AsDecimal() on a control of a row whose value reads empty ----

    [Test]
    procedure Ca01_AsDecimal_BlankZeroControlAndEmptyText()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        D: Decimal;
        I: Integer;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        Observer.Observe('blankzero-value', P.AmtBlankZero.Value());
        Observer.Observe('plain-value', P.AmtPlain.Value());
        if TryAmtBlankDec(P, D) then
            Observer.Observe('blankzero-asdecimal', Format(D))
        else
            Observer.ObserveError('blankzero-asdecimal');
        if TryAmtBlankInt(P, I) then
            Observer.Observe('blankzero-asinteger', Format(I))
        else
            Observer.ObserveError('blankzero-asinteger');
        Observer.Observe('text-value', P.TxtCtl.Value());
        if TryTxtDec(P, D) then
            Observer.Observe('emptytext-asdecimal', Format(D))
        else
            Observer.ObserveError('emptytext-asdecimal');
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Ca01_AsDecimal_TextControlWithNumberAndNonNumber()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        D: Decimal;
    begin
        Seed('A', 'n', 2.5, '12.5');
        OpenCard(P, 'A');
        Observer.Observe('blankzero-value', P.AmtBlankZero.Value());
        Observer.Observe('blankzero-asdecimal', Format(P.AmtBlankZero.AsDecimal()));
        if TryTxtDec(P, D) then
            Observer.Observe('number-text-asdecimal', Format(D))
        else
            Observer.ObserveError('number-text-asdecimal');
        P.TxtCtl.SetValue('abc');
        if TryTxtDec(P, D) then
            Observer.Observe('word-text-asdecimal', Format(D))
        else
            Observer.ObserveError('word-text-asdecimal');
        P.TxtCtl.SetValue(' ');
        Observer.Observe('space-text-value', '[' + P.TxtCtl.Value() + ']');
        if TryTxtDec(P, D) then
            Observer.Observe('space-text-asdecimal', Format(D))
        else
            Observer.ObserveError('space-text-asdecimal');
        P.Close();
        Observer.Finish();
    end;

    // ---- item 3: a TestPage of a Role Center page ----

    [TryFunction]
    local procedure TryRunRoleCenter()
    begin
        Page.Run(Page::"LT CA Role Center");
    end;

    [TryFunction]
    local procedure TryOpenRoleCenter(var Rc: TestPage "LT CA Role Center")
    begin
        Rc.OpenView();
    end;

    [TryFunction]
    local procedure TryRcCaption(var Rc: TestPage "LT CA Role Center"; var C: Text)
    begin
        C := Rc.Caption();
    end;

    [TryFunction]
    local procedure TryInvokeRcAction(var Rc: TestPage "LT CA Role Center")
    var
        L: TestPage "LT CA List";
    begin
        L.Trap();
        Rc.RcAction.Invoke();
        L.Close();
    end;

    [Test]
    procedure Ca03_RoleCenter_TrapThenPageRun()
    var
        Observer: Codeunit "Probe Observer";
        Rc: TestPage "LT CA Role Center";
        C: Text;
    begin
        Rc.Trap();
        if TryRunRoleCenter() then
            Observer.Observe('run', 'ok')
        else
            Observer.ObserveError('run');
        if TryRcCaption(Rc, C) then
            Observer.Observe('caption', C)
        else
            Observer.ObserveError('caption');
        if TryInvokeRcAction(Rc) then
            Observer.Observe('invoke', 'ok')
        else
            Observer.ObserveError('invoke');
        Observer.Finish();
    end;

    [Test]
    procedure Ca03_RoleCenter_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Rc: TestPage "LT CA Role Center";
        C: Text;
    begin
        if TryOpenRoleCenter(Rc) then
            Observer.Observe('openview', 'ok')
        else
            Observer.ObserveError('openview');
        if TryRcCaption(Rc, C) then
            Observer.Observe('caption', C)
        else
            Observer.ObserveError('caption');
        if TryInvokeRcAction(Rc) then
            Observer.Observe('invoke', 'ok')
        else
            Observer.ObserveError('invoke');
        Observer.Finish();
    end;

    // ---- item 6: a TestPage control's Value (and Format of the control) assigned to a Code variable ----

    [TryFunction]
    local procedure TryShortCode(var P: TestPage "LT CA Card"; var Short: Code[3])
    begin
        Short := P.NameCtl.Value;
    end;

    [Test]
    procedure Ca06_ValueAndFormatIntoCodeAndText()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        C: Code[20];
        Short: Code[3];
        T: Text;
    begin
        Seed('ABC', 'mixed Case', 0, '');
        OpenCard(P, 'ABC');
        C := P.CodeCtl.Value;
        Observer.Observe('code-from-code-value', C);
        C := P.NameCtl.Value;
        Observer.Observe('code-from-text-value', C);
        C := Format(P.CodeCtl);
        Observer.Observe('code-from-format-control', C);
        T := Format(P.NameCtl);
        Observer.Observe('text-from-format-control', T);
        T := P.NameCtl.Value;
        Observer.Observe('text-from-value', T);
        if TryShortCode(P, Short) then
            Observer.Observe('code3-from-long-value', Short)
        else
            Observer.ObserveError('code3-from-long-value');
        P.Close();
        Observer.Finish();
    end;

    // ---- item 7: Caption of a TestPage control read without parentheses ----

    [Test]
    procedure Ca07_CaptionWithoutParentheses()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        T: Text;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        T := P.NameCtl.Caption;
        Observer.Observe('name-caption-property', T);
        Observer.Observe('name-caption-method', P.NameCtl.Caption());
        T := P.CodeCtl.Caption;
        Observer.Observe('code-caption-property', T);
        P.Close();
        Observer.Finish();
    end;

    // ---- item 9: New() on a list page whose CardPageId names a card, with the card trapped ----

    [TryFunction]
    local procedure TrySetCardCode(var Card: TestPage "LT CA Card"; V: Text)
    begin
        Card.CodeCtl.SetValue(V);
    end;

    [TryFunction]
    local procedure TryListNew(var L: TestPage "LT CA List")
    begin
        L.New();
    end;

    [TryFunction]
    local procedure TryEditableListNew(var L: TestPage "LT CA Editable List")
    begin
        L.New();
    end;

    [TryFunction]
    local procedure TryReadListCode(var L: TestPage "LT CA Editable List"; var V: Text)
    begin
        V := L.CodeCtl.Value();
    end;

    [Test]
    procedure Ca09_NotEditableList_New_TrappedCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CA Row";
        L: TestPage "LT CA List";
        Card: TestPage "LT CA Card";
    begin
        Seed('A', 'n', 0, '');
        L.OpenView();
        Card.Trap();
        if TryListNew(L) then
            Observer.Observe('new', 'ok')
        else
            Observer.ObserveError('new');
        if TrySetCardCode(Card, 'NEWROW') then
            Observer.Observe('card-setvalue', 'ok')
        else
            Observer.ObserveError('card-setvalue');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Ca09_EditableList_New_TrappedCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CA Row";
        L: TestPage "LT CA Editable List";
        Card: TestPage "LT CA Card";
        V: Text;
    begin
        Seed('A', 'n', 0, '');
        L.OpenEdit();
        Card.Trap();
        if TryEditableListNew(L) then
            Observer.Observe('new', 'ok')
        else
            Observer.ObserveError('new');
        if TrySetCardCode(Card, 'NEWROW') then
            Observer.Observe('card-setvalue', 'ok')
        else
            Observer.ObserveError('card-setvalue');
        if TryReadListCode(L, V) then
            Observer.Observe('list-code-after-new', '[' + V + ']')
        else
            Observer.ObserveError('list-code-after-new');
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Finish();
    end;

    // ---- item 15: OK() and Cancel() return a TestAction that can be held in a Variant ----

    [TryFunction]
    local procedure TryReadCardCode(var P: TestPage "LT CA Card"; var V: Text)
    begin
        V := P.CodeCtl.Value();
    end;

    [Test]
    procedure Ca15_OkIntoVariant_DoesNotClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT CA Card";
        V: Variant;
        T: Text;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        V := P.OK();
        Observer.Observe('variant-isaction', Format(V.IsAction()));
        Observer.Observe('variant-format', Format(V));
        if TryReadCardCode(P, T) then
            Observer.Observe('read-after-ok-into-variant', T)
        else
            Observer.ObserveError('read-after-ok-into-variant');
        V := P.Cancel();
        if TryReadCardCode(P, T) then
            Observer.Observe('read-after-cancel-into-variant', T)
        else
            Observer.ObserveError('read-after-cancel-into-variant');
        P.OK().Invoke();
        if TryReadCardCode(P, T) then
            Observer.Observe('read-after-ok-invoke', T)
        else
            Observer.ObserveError('read-after-ok-invoke');
        Observer.Finish();
    end;

    // ---- item 16: a Dialog local to a page action, and one global to the page ----

    [TryFunction]
    local procedure TryInvoke(var P: TestPage "LT CA Card"; Which: Integer)
    begin
        case Which of
            1:
                P.DialogLocal.Invoke();
            2:
                P.DialogGlobal.Invoke();
            3:
                P.DialogGlobalLeftOpen.Invoke();
        end;
    end;

    [Test]
    procedure Ca16_DialogLocalAndGlobalInPageAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CA Log";
        P: TestPage "LT CA Card";
        Which: Integer;
    begin
        Seed('A', 'n', 0, '');
        OpenCard(P, 'A');
        for Which := 1 to 3 do begin
            if TryInvoke(P, Which) then
                Observer.Observe('invoke' + Format(Which), 'ok')
            else
                Observer.ObserveError('invoke' + Format(Which));
            Observer.Observe('log' + Format(Which), Log.Take());
        end;
        if TryInvoke(P, 3) then
            Observer.Observe('invoke3-again', 'ok')
        else
            Observer.ObserveError('invoke3-again');
        Observer.Observe('log3-again', Log.Take());
        P.Close();
        Observer.Finish();
    end;
}
