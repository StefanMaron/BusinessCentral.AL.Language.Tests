// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160); AhPageObjects.al (tables 78610, 78616, 78617; pages 78611-78615, 78618, 78619); own codeunits 78620-78622
// Probe (corpus issue 636): item 5 TestPage Close after a refused SetValue (MinValue/MaxValue, failed number conversion, OnValidate, CharAllowed);
// item 6 GetValidationError() with three or more errors; item 7 CharAllowed with several ranges; item 4 a ShowAsTree repeater opened through
// Page.Run / a Page variable; item 8 a part edit when the host is a list over the same table and when it is a document page.
// BC versions: 27+

codeunit 78620 "LT AH Card Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'R1';
        Row.Txt := 'orig';
        Row.Qty := 5;
        Row.Dec := 1;
        Row.Name := 'n0';
        Row.Other := 'o0';
        Row.Insert();
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT AH Row";
    begin
        if not Row.Get('R1') then
            exit('row missing');
        exit('Txt=' + Row.Txt + '|Qty=' + Format(Row.Qty) + '|Dec=' + Format(Row.Dec) + '|Name=' + Row.Name + '|Other=' + Row.Other + '|Guard=' + Row.Guard + '|Letters=' + Row.Letters);
    end;

    [TryFunction]
    local procedure TryClose(var P: TestPage "LT AH Card")
    begin
        P.Close();
    end;

    local procedure CloseObserved(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AH Card")
    begin
        Observer.Observe('close_ok', Format(TryClose(P)));
        if GetLastErrorText() <> '' then
            Observer.ObserveError('close_error');
        Observer.Observe('stored', Stored());
    end;

    [Test]
    procedure Close_AfterRefusedMaxValue_KeepsValidEdits()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        Observer.Observe('count_before_close', Format(P.ValidationErrorCount()));
        Observer.Observe('qty_value_on_page', P.QtyCtl.Value());
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterRefusedMinValueDecimal()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.NameCtl.SetValue('n1');
        asserterror P.DecCtl.SetValue(-5);
        Observer.ObserveError('refused');
        Observer.Observe('dec_value_on_page', P.DecCtl.Value());
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterFailedIntegerConversion()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.QtyCtl.SetValue('abc');
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        Observer.Observe('qty_value_on_page', P.QtyCtl.Value());
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterFailedDecimalConversion()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.DecCtl.SetValue('x1');
        Observer.ObserveError('refused');
        Observer.Observe('dec_value_on_page', P.DecCtl.Value());
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterRefusedOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.GuardCtl.SetValue('bad');
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterRefusedCharAllowed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterOnlyRefusedEdit()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused');
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterRefusedThenValidOnSameField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused');
        Observer.Observe('count_after_refusal', Format(P.ValidationErrorCount()));
        P.QtyCtl.SetValue(7);
        Observer.Observe('count_after_valid_retry', Format(P.ValidationErrorCount()));
        P.TxtCtl.SetValue('new');
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure Close_AfterTwoRefusalsOnDifferentFields()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.QtyCtl.SetValue(0);
        Observer.ObserveError('refused_qty');
        asserterror P.DecCtl.SetValue(101);
        Observer.ObserveError('refused_dec');
        P.NameCtl.SetValue('n1');
        CloseObserved(Observer, P);
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_ThreeControls()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused_qty');
        asserterror P.DecCtl.SetValue(-5);
        Observer.ObserveError('refused_dec');
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.ObserveError('refused_letters');
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Observe('page_1', P.GetValidationError(1));
        Observer.Observe('page_2', P.GetValidationError(2));
        Observer.Observe('page_3', P.GetValidationError(3));
        asserterror Observer.Observe('page_4', P.GetValidationError(4));
        Observer.ObserveError('page_4_error');
        Observer.Observe('qty_count', Format(P.QtyCtl.ValidationErrorCount()));
        Observer.Observe('qty_no_index', P.QtyCtl.GetValidationError());
        Observer.Observe('dec_count', Format(P.DecCtl.ValidationErrorCount()));
        Observer.Observe('dec_no_index', P.DecCtl.GetValidationError());
        Observer.Observe('letters_count', Format(P.LettersCtl.ValidationErrorCount()));
        Observer.Observe('letters_no_index', P.LettersCtl.GetValidationError());
        Observer.Observe('txt_count', Format(P.TxtCtl.ValidationErrorCount()));
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_TwoErrorsOnOneControl_AndAnotherControl()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused_qty_1');
        asserterror P.QtyCtl.SetValue('abc');
        Observer.ObserveError('refused_qty_2');
        asserterror P.DecCtl.SetValue(-5);
        Observer.ObserveError('refused_dec');
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Observe('page_1', P.GetValidationError(1));
        Observer.Observe('page_2', P.GetValidationError(2));
        Observer.Observe('page_3', P.GetValidationError(3));
        Observer.Observe('qty_count', Format(P.QtyCtl.ValidationErrorCount()));
        Observer.Observe('qty_no_index', P.QtyCtl.GetValidationError());
        Observer.Observe('qty_1', P.QtyCtl.GetValidationError(1));
        Observer.Observe('qty_2', P.QtyCtl.GetValidationError(2));
        Observer.Observe('dec_count', Format(P.DecCtl.ValidationErrorCount()));
        Observer.Observe('dec_1', P.DecCtl.GetValidationError(1));
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_NoIndex_OneError()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused_qty');
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Observe('page_1', P.GetValidationError(1));
        Observer.Observe('qty_no_index', P.QtyCtl.GetValidationError());
        Observer.Observe('qty_1', P.QtyCtl.GetValidationError(1));
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_PageNoIndex_NoErrors()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
        Text: Text;
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        asserterror Text := P.GetValidationError();
        Observer.ObserveError('page_no_index_error');
        Observer.Finish();
    end;

    [Test]
    procedure GetValidationError_CountAfterCorrections()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused_qty');
        asserterror P.DecCtl.SetValue(-5);
        Observer.ObserveError('refused_dec');
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.ObserveError('refused_letters');
        P.QtyCtl.SetValue(3);
        Observer.Observe('page_count_after_qty_fix', Format(P.ValidationErrorCount()));
        Observer.Observe('qty_count_after_qty_fix', Format(P.QtyCtl.ValidationErrorCount()));
        Observer.Observe('page_1_after_qty_fix', P.GetValidationError(1));
        P.DecCtl.SetValue(3);
        P.LettersCtl.SetValue('abc');
        Observer.Observe('page_count_after_all_fixed', Format(P.ValidationErrorCount()));
        Observer.Finish();
    end;
}

codeunit 78623 "LT AH CharAllowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'R1';
        Row.Insert();
    end;

    [TryFunction]
    local procedure SetThree(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.ThreeRanges.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetSingles(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.SinglesAndRange.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetUnordered(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.Unordered.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetNonAscii(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.NonAscii.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetOneRangeMany(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.OneRangeMany.SetValue(Value);
    end;

    local procedure Candidates(): Text
    var
        Result: Text;
        C: Text[1];
        I: Integer;
        Extra: List of [Integer];
    begin
        for I := 33 to 126 do begin
            C[1] := I;
            Result += C;
        end;
        Extra.Add(196);
        Extra.Add(214);
        Extra.Add(220);
        Extra.Add(223);
        Extra.Add(228);
        Extra.Add(246);
        Extra.Add(252);
        Extra.Add(1040);
        foreach I in Extra do begin
            C[1] := I;
            Result += C;
        end;
        exit(Result);
    end;

    [Test]
    procedure ThreeRanges_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetThree(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Observe('mixed_ok', Format(SetThree(P, 'aZ9bY8')));
        Observer.Observe('mixed_value', P.ThreeRanges.Value());
        Observer.Observe('mixed_with_dash', Format(SetThree(P, 'aZ9-')));
        Observer.Observe('mixed_with_dash_value', P.ThreeRanges.Value());
        asserterror P.ThreeRanges.SetValue('a b');
        Observer.ObserveError('with_space');
        Observer.Finish();
    end;

    [Test]
    procedure SinglesAndRange_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetSingles(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Observe('mixed_ok', Format(SetSingles(P, '12-_34')));
        Observer.Observe('mixed_value', P.SinglesAndRange.Value());
        asserterror P.SinglesAndRange.SetValue('12-_a');
        Observer.ObserveError('with_letter');
        Observer.Finish();
    end;

    [Test]
    procedure UnorderedSingles_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetUnordered(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Finish();
    end;

    [Test]
    procedure NonAsciiSingle_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetNonAscii(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Finish();
    end;

    [Test]
    procedure TwoRangesOfLetters_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetOneRangeMany(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Finish();
    end;
}

codeunit 78621 "LT AH Tree Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Tag: Text;

    local procedure Seed()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        AddRow('T1', 0);
        AddRow('T2', 1);
        AddRow('T3', 2);
        AddRow('T4', 1);
        AddRow('T5', 0);
    end;

    local procedure AddRow(Id: Code[20]; Level: Integer)
    var
        Row: Record "LT AH Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Txt := 'text ' + Id;
        Row.Lvl := Level;
        Row.Insert();
    end;

    local procedure Rows(var P: TestPage "LT AH Tree"): Text
    var
        Result: Text;
    begin
        if P.First() then
            repeat
                Result += P.IdCtl.Value() + ' ';
            until not P.Next();
        exit(Result);
    end;

    local procedure Walk(var P: TestPage "LT AH Tree")
    begin
        Observer.Observe(Tag + '_rows_initial', Rows(P));
        P.First();
        Observer.Observe(Tag + '_first', P.IdCtl.Value());
        Observer.Observe(Tag + '_first_expanded', Format(P.IsExpanded()));
        P.Expand(true);
        Observer.Observe(Tag + '_first_expanded_after_expand', Format(P.IsExpanded()));
        Observer.Observe(Tag + '_rows_after_expand', Rows(P));
        P.GoToKey('T1');
        P.Expand(false);
        Observer.Observe(Tag + '_rows_after_collapse', Rows(P));
        Observer.Observe(Tag + '_goto_child', Format(P.GoToKey('T2')));
        P.GoToKey('T5');
        Observer.Observe(Tag + '_last_root_expanded', Format(P.IsExpanded()));
    end;

    [PageHandler]
    procedure TreeHandler(var P: TestPage "LT AH Tree")
    begin
        Walk(P);
    end;

    [ModalPageHandler]
    procedure TreeModalHandler(var P: TestPage "LT AH Tree")
    begin
        Walk(P);
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure Tree_ThroughPageRun()
    begin
        Seed();
        Tag := 'page_run';
        Page.Run(Page::"LT AH Tree");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure Tree_ThroughPageVariableRun()
    var
        Pg: Page "LT AH Tree";
    begin
        Seed();
        Tag := 'variable_run';
        Pg.Run();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TreeModalHandler')]
    procedure Tree_ThroughPageVariableRunModal()
    var
        Pg: Page "LT AH Tree";
    begin
        Seed();
        Tag := 'variable_runmodal';
        Pg.RunModal();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TreeModalHandler')]
    procedure Tree_ThroughPageRunModal()
    begin
        Seed();
        Tag := 'page_runmodal';
        Page.RunModal(Page::"LT AH Tree");
        Observer.Finish();
    end;

    [Test]
    procedure Tree_ThroughTestPageVariable()
    var
        P: TestPage "LT AH Tree";
    begin
        Seed();
        Tag := 'testpage';
        P.OpenView();
        Walk(P);
        P.Close();
        Observer.Finish();
    end;
}

codeunit 78622 "LT AH Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRows()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        AddRow('R1', 'a', 1);
        AddRow('R2', 'b', 2);
        AddRow('R3', 'c', 3);
    end;

    local procedure AddRow(Id: Code[20]; Txt: Text[30]; Qty: Integer)
    var
        Row: Record "LT AH Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Txt := Txt;
        Row.Qty := Qty;
        Row.Insert();
    end;

    local procedure DumpRows(): Text
    var
        Row: Record "LT AH Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row.Id + '=' + Row.Txt + '/' + Format(Row.Qty) + ' ';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure PartRows(var Host: TestPage "LT AH Host List"): Text
    var
        Result: Text;
    begin
        if Host.SamePart.First() then
            repeat
                Result += Host.SamePart.IdCtl.Value() + '=' + Host.SamePart.TxtCtl.Value() + ' ';
            until not Host.SamePart.Next();
        exit(Result);
    end;

    [Test]
    procedure ListHost_PartEdit_SavedOnHostClose()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Observer.Observe('part_rows', PartRows(Host));
        Host.SamePart.TxtCtl.SetValue('viaPart');
        Observer.Observe('part_value_after_edit', Host.SamePart.TxtCtl.Value());
        Observer.Observe('host_value_after_edit', Host.TxtCtl.Value());
        Observer.Observe('db_after_edit', DumpRows());
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Finish();
    end;

    [Test]
    procedure ListHost_PartEdit_ThenHostRowChange()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Host.SamePart.TxtCtl.SetValue('viaPart');
        Host.GoToKey('R3');
        Observer.Observe('db_after_row_change', DumpRows());
        Observer.Observe('part_rows_on_r3', PartRows(Host));
        Host.GoToKey('R2');
        Observer.Observe('host_value_back_on_r2', Host.TxtCtl.Value());
        Observer.Observe('part_value_back_on_r2', Host.SamePart.TxtCtl.Value());
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Finish();
    end;

    [Test]
    procedure ListHost_HostEditThenPartEditOfSameRow()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Host.TxtCtl.SetValue('viaHost');
        Observer.Observe('part_value_after_host_edit', Host.SamePart.TxtCtl.Value());
        Host.SamePart.QtyCtl.SetValue(7);
        Observer.Observe('host_qty_after_part_edit', Host.QtyCtl.Value());
        Observer.Observe('host_txt_after_part_edit', Host.TxtCtl.Value());
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Finish();
    end;

    [Test]
    procedure ListHost_PartEditRefused()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Host.TxtCtl.SetValue('viaHost');
        asserterror Host.SamePart.QtyCtl.SetValue(99);
        Observer.ObserveError('part_refused');
        Observer.Observe('host_error_count', Format(Host.ValidationErrorCount()));
        Observer.Observe('part_error_count', Format(Host.SamePart.ValidationErrorCount()));
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Finish();
    end;

    local procedure SeedDocument()
    var
        Head: Record "LT AH Head";
        Line: Record "LT AH Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Init();
        Head.Id := 'H1';
        Head.Descr := 'head';
        Head.Insert();
        AddLine(10, 'first', 1);
        AddLine(20, 'second', 2);
        Head.Id := 'H2';
        Head.Descr := 'other head';
        Head.Insert();
        Line.Init();
        Line.HeadId := 'H2';
        Line.LineNo := 10;
        Line.Descr := 'foreign';
        Line.Insert();
    end;

    local procedure AddLine(LineNo: Integer; Descr: Text[30]; Amount: Decimal)
    var
        Line: Record "LT AH Line";
    begin
        Line.Init();
        Line.HeadId := 'H1';
        Line.LineNo := LineNo;
        Line.Descr := Descr;
        Line.Amount := Amount;
        Line.Insert();
    end;

    local procedure DumpHeadsAndLines(): Text
    var
        Head: Record "LT AH Head";
        Line: Record "LT AH Line";
        Result: Text;
    begin
        if Head.FindSet() then
            repeat
                Result += 'H:' + Head.Id + '=' + Head.Descr + ' ';
            until Head.Next() = 0;
        if Line.FindSet() then
            repeat
                Result += 'L:' + Line.HeadId + '/' + Format(Line.LineNo) + '=' + Line.Descr + '/' + Format(Line.Amount) + ' ';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure LinesOf(var Doc: TestPage "LT AH Document"): Text
    var
        Result: Text;
    begin
        if Doc.Lines.First() then
            repeat
                Result += Doc.Lines.LineNoCtl.Value() + '=' + Doc.Lines.DescrCtl.Value() + ' ';
            until not Doc.Lines.Next();
        exit(Result);
    end;

    [Test]
    procedure DocumentHost_PartEditExistingLine()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Observer.Observe('lines', LinesOf(Doc));
        Doc.Lines.GoToKey(10);
        Doc.Lines.DescrCtl.SetValue('edited');
        Observer.Observe('db_after_edit', DumpHeadsAndLines());
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Finish();
    end;

    [Test]
    procedure DocumentHost_PartNewLine()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('added');
        Doc.Lines.AmountCtl.SetValue(5);
        Observer.Observe('new_line_no', Doc.Lines.LineNoCtl.Value());
        Observer.Observe('db_after_new', DumpHeadsAndLines());
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Finish();
    end;

    [Test]
    procedure DocumentHost_HeaderEditAndPartEdit()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.DescrCtl.SetValue('head edited');
        Doc.Lines.GoToKey(20);
        Doc.Lines.AmountCtl.SetValue(22);
        Doc.Lines.GoToKey(10);
        Observer.Observe('db_after_row_change', DumpHeadsAndLines());
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Finish();
    end;

    [Test]
    procedure DocumentHost_PartEditRefused_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.DescrCtl.SetValue('head edited');
        Doc.Lines.GoToKey(20);
        Doc.Lines.DescrCtl.SetValue('part edited');
        asserterror Doc.Lines.AmountCtl.SetValue('abc');
        Observer.ObserveError('part_refused');
        Observer.Observe('host_error_count', Format(Doc.ValidationErrorCount()));
        Observer.Observe('part_error_count', Format(Doc.Lines.ValidationErrorCount()));
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Finish();
    end;
}
