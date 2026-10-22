// Probes: md:12 (decimal beyond two places outside MinValue/MaxValue), md:18 (control bound to a page-global temporary record),
// md:94 / md:118 / md:119 (texts and ids of the not-found errors, GetField by id).

table 69233 "W1 Ctl Buf"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "W1 Ctl Log";
            begin
                Log.Add('table:Value=' + Value);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69240 "W1 Ctl Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 69250 "W1 MinMax Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(DecVar; DecVar)
            {
                MinValue = 0.5;
                MaxValue = 2.5;
            }
            field(DecBound3; DecBound3)
            {
                MinValue = 0.495;
                MaxValue = 2.505;
            }
        }
    }

    var
        DecVar: Decimal;
        DecBound3: Decimal;
}

page 69251 "W1 Ctl Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
        }
    }
}

page 69252 "W1 Hidden Host A"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Vis; Rec.Id) { }
            field(HidA; Rec.Name) { Visible = false; }
            field(HidB; Rec.Grp) { Visible = false; }
            field(AreaFld; Rec.Amount) { ApplicationArea = Suite; }
            part(HidPart; "W1 Ctl Part")
            {
                Visible = false;
                SubPageLink = Grp = field(Id);
            }
            part(HidPartB; "W1 Ctl Part")
            {
                Visible = false;
                SubPageLink = Grp = field(Id);
            }
            part(AreaPart; "W1 Ctl Part")
            {
                ApplicationArea = Suite;
                SubPageLink = Grp = field(Id);
            }
            part(VisPart; "W1 Ctl Part")
            {
                SubPageLink = Grp = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AreaAct)
            {
                ApplicationArea = Suite;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

// Same control names as host A, other page id: the generated id should differ.
page 69253 "W1 Hidden Host B"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(Vis; Rec.Id) { }
            field(HidA; Rec.Name) { Visible = false; }
            part(HidPart; "W1 Ctl Part")
            {
                Visible = false;
                SubPageLink = Grp = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AreaAct)
            {
                ApplicationArea = Suite;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

pageextension 69254 "W1 Hidden Host A Ext" extends "W1 Hidden Host A"
{
    layout
    {
        addlast(Content)
        {
            field(ExtHid; Rec.Name) { Visible = false; }
            field(HidA2; Rec.Name) { Visible = false; }
        }
    }
}

page 69255 "W1 Visible Fields Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "W1 Row";

    layout
    {
        area(Content)
        {
            field(FldId; Rec.Id) { }
            field(FldName; Rec.Name) { }
            field(FldAmount; Rec.Amount) { }
        }
    }
}

page 69256 "W1 Temp Bind Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(C; TempBuf.Value)
            {
                trigger OnValidate()
                begin
                    Log.Add('page:C=' + TempBuf.Value);
                end;
            }
            field(D; TempBuf.Value) { }
            field(TabId; TempBuf.Id) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowBuf)
            {
                trigger OnAction()
                begin
                    Log.Add('buf=' + TempBuf.Value);
                end;
            }
        }
    }

    var
        TempBuf: Record "W1 Ctl Buf" temporary;
        Log: Codeunit "W1 Ctl Log";

    trigger OnOpenPage()
    begin
        TempBuf.Id := 1;
        TempBuf.Value := 'init';
        TempBuf.Insert();
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGCR');
    end;
}

codeunit 69260 "W1 Controls Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W1 Ctl Log";

    [TryFunction]
    local procedure TrySetDec(var Pg: TestPage "W1 MinMax Card"; Value: Decimal)
    begin
        Pg.DecVar.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetDec3(var Pg: TestPage "W1 MinMax Card"; Value: Decimal)
    begin
        Pg.DecBound3.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetTemp(var Pg: TestPage "W1 Temp Bind Card"; Value: Text)
    begin
        Pg.C.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryGetFieldValue(var Pg: TestPage "W1 Visible Fields Card"; ControlId: Integer; var Result: Text)
    begin
        Result := Pg.GetField(ControlId).Value();
    end;

    local procedure TryDec(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W1 MinMax Card"; Label: Text; Value: Decimal)
    begin
        Pg.DecVar.SetValue(1.5);
        if TrySetDec(Pg, Value) then
            Observer.Observe(Label + '|accepted', Pg.DecVar.Value())
        else begin
            Observer.ObserveError(Label);
            Observer.Observe(Label + '|value_after', Pg.DecVar.Value());
        end;
    end;

    local procedure TryDec3(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W1 MinMax Card"; Label: Text; Value: Decimal)
    begin
        Pg.DecBound3.SetValue(1.5);
        if TrySetDec3(Pg, Value) then
            Observer.Observe(Label + '|accepted', Pg.DecBound3.Value())
        else begin
            Observer.ObserveError(Label);
            Observer.Observe(Label + '|value_after', Pg.DecBound3.Value());
        end;
    end;

    local procedure SeedRows()
    var
        Row: Record "W1 Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    // md:12: a decimal control with MaxValue 2.5 / MinValue 0.5: values with more than two decimals that are outside the bound only in the third or later place.
    [Test]
    procedure Decimal_ThreePlacesJustOutsideTwoDecimalBounds()
    var
        Pg: TestPage "W1 MinMax Card";
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Pg.OpenEdit();
        TryDec(Observer, Pg, 'max_2.501', 2.501);
        TryDec(Observer, Pg, 'max_2.5049', 2.5049);
        TryDec(Observer, Pg, 'max_2.505', 2.505);
        TryDec(Observer, Pg, 'max_2.6', 2.6);
        TryDec(Observer, Pg, 'min_0.499', 0.499);
        TryDec(Observer, Pg, 'min_0.4951', 0.4951);
        TryDec(Observer, Pg, 'min_0.495', 0.495);
        TryDec(Observer, Pg, 'min_0.4', 0.4);
        Pg.Close();
        Observer.Expect('max_2.501|accepted', '2.50');
        Observer.Expect('max_2.5049|accepted', '2.50');
        Observer.Expect('max_2.505|text', 'Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 2.5. Value: 2.51.''');
        Observer.Expect('max_2.505|code', 'TestValidation');
        Observer.Expect('max_2.505|value_after', '1.50');
        Observer.Expect('max_2.6|text', 'Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 2.5. Value: 2.60.''');
        Observer.Expect('max_2.6|code', 'TestValidation');
        Observer.Expect('max_2.6|value_after', '1.50');
        Observer.Expect('min_0.499|accepted', '0.50');
        Observer.Expect('min_0.4951|accepted', '0.50');
        Observer.Expect('min_0.495|accepted', '0.50');
        Observer.Expect('min_0.4|text', 'Validation error for Field: DecVar,  Message = ''The value must be greater than or equal to 0.5. Value: 0.40.''');
        Observer.Expect('min_0.4|code', 'TestValidation');
        Observer.Expect('min_0.4|value_after', '1.50');
        Observer.Verify();
    end;

    // md:12: the bound itself has three decimals (0.495 / 2.505); values around it.
    [Test]
    procedure Decimal_BoundsWithThreePlaces()
    var
        Pg: TestPage "W1 MinMax Card";
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Pg.OpenEdit();
        TryDec3(Observer, Pg, 'b3_max_2.505', 2.505);
        TryDec3(Observer, Pg, 'b3_max_2.5051', 2.5051);
        TryDec3(Observer, Pg, 'b3_max_2.506', 2.506);
        TryDec3(Observer, Pg, 'b3_max_2.5054', 2.5054);
        TryDec3(Observer, Pg, 'b3_min_0.495', 0.495);
        TryDec3(Observer, Pg, 'b3_min_0.4949', 0.4949);
        TryDec3(Observer, Pg, 'b3_min_0.4945', 0.4945);
        TryDec3(Observer, Pg, 'b3_min_0.49', 0.49);
        TryDec3(Observer, Pg, 'b3_max_2.51', 2.51);
        Pg.Close();
        Observer.Expect('b3_max_2.505|text', 'Validation error for Field: DecBound3,  Message = ''The value must be less than or equal to 2.505. Value: 2.51.''');
        Observer.Expect('b3_max_2.505|code', 'TestValidation');
        Observer.Expect('b3_max_2.505|value_after', '1.50');
        Observer.Expect('b3_max_2.5051|text', 'Validation error for Field: DecBound3,  Message = ''The value must be less than or equal to 2.505. Value: 2.51.''');
        Observer.Expect('b3_max_2.5051|code', 'TestValidation');
        Observer.Expect('b3_max_2.5051|value_after', '1.50');
        Observer.Expect('b3_max_2.506|text', 'Validation error for Field: DecBound3,  Message = ''The value must be less than or equal to 2.505. Value: 2.51.''');
        Observer.Expect('b3_max_2.506|code', 'TestValidation');
        Observer.Expect('b3_max_2.506|value_after', '1.50');
        Observer.Expect('b3_max_2.5054|text', 'Validation error for Field: DecBound3,  Message = ''The value must be less than or equal to 2.505. Value: 2.51.''');
        Observer.Expect('b3_max_2.5054|code', 'TestValidation');
        Observer.Expect('b3_max_2.5054|value_after', '1.50');
        Observer.Expect('b3_min_0.495|accepted', '0.50');
        Observer.Expect('b3_min_0.4949|text', 'Validation error for Field: DecBound3,  Message = ''The value must be greater than or equal to 0.495. Value: 0.49.''');
        Observer.Expect('b3_min_0.4949|code', 'TestValidation');
        Observer.Expect('b3_min_0.4949|value_after', '1.50');
        Observer.Expect('b3_min_0.4945|text', 'Validation error for Field: DecBound3,  Message = ''The value must be greater than or equal to 0.495. Value: 0.49.''');
        Observer.Expect('b3_min_0.4945|code', 'TestValidation');
        Observer.Expect('b3_min_0.4945|value_after', '1.50');
        Observer.Expect('b3_min_0.49|text', 'Validation error for Field: DecBound3,  Message = ''The value must be greater than or equal to 0.495. Value: 0.49.''');
        Observer.Expect('b3_min_0.49|code', 'TestValidation');
        Observer.Expect('b3_min_0.49|value_after', '1.50');
        Observer.Expect('b3_max_2.51|text', 'Validation error for Field: DecBound3,  Message = ''The value must be less than or equal to 2.505. Value: 2.51.''');
        Observer.Expect('b3_max_2.51|code', 'TestValidation');
        Observer.Expect('b3_max_2.51|value_after', '1.50');
        Observer.Verify();
    end;

    // md:18: write through a control bound to a field of a page-global temporary record.
    [Test]
    procedure TempRecordControl_SetValue()
    var
        Pg: TestPage "W1 Temp Bind Card";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('open_log', Log.Take());
        Observer.Observe('c_open', Pg.C.Value());
        Observer.Observe('d_open', Pg.D.Value());
        Observer.Observe('id_open', Pg.TabId.Value());
        if TrySetTemp(Pg, 'changed') then
            Observer.Observe('set_c', 'ok')
        else
            Observer.ObserveError('set_c');
        Observer.Observe('set_log', Log.Take());
        Observer.Observe('c_after', Pg.C.Value());
        Observer.Observe('d_after', Pg.D.Value());
        Pg.ShowBuf.Invoke();
        Observer.Observe('buf_log', Log.Take());
        Pg.Close();
        Observer.Expect('open_log', 'OnOpenPage;AGCR;');
        Observer.Expect('c_open', 'init');
        Observer.Expect('d_open', 'init');
        Observer.Expect('id_open', '1');
        Observer.Expect('set_c', 'ok');
        Observer.Expect('set_log', 'page:C=changed;');
        Observer.Expect('c_after', 'changed');
        Observer.Expect('d_after', 'changed');
        Observer.Expect('buf_log', 'buf=changed;AGCR;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryVisibleA(var Pg: TestPage "W1 Hidden Host A"; Which: Text; var Result: Boolean)
    begin
        case Which of
            'HidA':
                Result := Pg.HidA.Visible();
            'HidB':
                Result := Pg.HidB.Visible();
            'ExtHid':
                Result := Pg.ExtHid.Visible();
            'HidA2':
                Result := Pg.HidA2.Visible();
        end;
    end;

    [TryFunction]
    local procedure TryPartRows(var Pg: TestPage "W1 Hidden Host A"; Which: Text; var Result: Boolean)
    begin
        case Which of
            'HidPart':
                Result := Pg.HidPart.First();
            'HidPartB':
                Result := Pg.HidPartB.First();
        end;
    end;

    [TryFunction]
    local procedure TryVisibleB(var Pg: TestPage "W1 Hidden Host B"; Which: Text; var Result: Boolean)
    begin
        case Which of
            'HidA':
                Result := Pg.HidA.Visible();
            'HidPart':
                Result := Pg.HidPart.First();
        end;
    end;

    local procedure ProbeA(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W1 Hidden Host A"; Which: Text)
    var
        Result: Boolean;
    begin
        if TryVisibleA(Pg, Which, Result) then
            Observer.Observe('A_' + Which, 'no error, Visible()=' + Format(Result))
        else
            Observer.ObserveError('A_' + Which);
    end;

    local procedure ProbePartA(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W1 Hidden Host A"; Which: Text)
    var
        Result: Boolean;
    begin
        if TryPartRows(Pg, Which, Result) then
            Observer.Observe('A_' + Which, 'no error, First()=' + Format(Result))
        else
            Observer.ObserveError('A_' + Which);
    end;

    local procedure ProbeB(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W1 Hidden Host B"; Which: Text)
    var
        Result: Boolean;
    begin
        if TryVisibleB(Pg, Which, Result) then
            Observer.Observe('B_' + Which, 'no error, result=' + Format(Result))
        else
            Observer.ObserveError('B_' + Which);
    end;

    // md:94 / md:118: the exact text and code of the errors for controls that are not on the runtime page
    // (Visible = false on a field and on a part; the field and part ids come from the generated control ids).
    [Test]
    procedure NotFound_HiddenControls_TextAndCode()
    var
        HostA: TestPage "W1 Hidden Host A";
        HostB: TestPage "W1 Hidden Host B";
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        HostA.OpenEdit();
        ProbeA(Observer, HostA, 'HidA');
        ProbeA(Observer, HostA, 'HidB');
        ProbeA(Observer, HostA, 'ExtHid');
        ProbeA(Observer, HostA, 'HidA2');
        ProbePartA(Observer, HostA, 'HidPart');
        ProbePartA(Observer, HostA, 'HidPartB');
        HostA.Close();
        HostB.OpenEdit();
        ProbeB(Observer, HostB, 'HidA');
        ProbeB(Observer, HostB, 'HidPart');
        HostB.Close();
        Observer.Expect('A_HidA|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('A_HidA|code', 'TestFieldNotFound');
        Observer.Expect('A_HidB|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('A_HidB|code', 'TestFieldNotFound');
        Observer.Expect('A_ExtHid|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('A_ExtHid|code', 'TestFieldNotFound');
        Observer.Expect('A_HidA2|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('A_HidA2|code', 'TestFieldNotFound');
        Observer.Expect('A_HidPart|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('A_HidPart|code', 'TestPartNotFound');
        Observer.Expect('A_HidPartB|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('A_HidPartB|code', 'TestPartNotFound');
        Observer.Expect('B_HidA|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('B_HidA|code', 'TestFieldNotFound');
        Observer.Expect('B_HidPart|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('B_HidPart|code', 'TestPartNotFound');
        Observer.Verify();
    end;

    // md:94 / md:118: controls removed by application area (field, part, action), and the code of the not-found action.
    [Test]
    procedure NotFound_ControlsRemovedByArea_TextAndCode()
    var
        HostA: TestPage "W1 Hidden Host A";
        HostB: TestPage "W1 Hidden Host B";
        Observer: Codeunit "Probe Observer";
        PreviousAreas: Text;
        Flag: Boolean;
    begin
        SeedRows();
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic');
        HostA.OpenEdit();
        asserterror Flag := HostA.AreaFld.Visible();
        Observer.ObserveError('A_AreaFld_field');
        asserterror HostA.AreaPart.First();
        Observer.ObserveError('A_AreaPart_part');
        asserterror HostA.AreaAct.Invoke();
        Observer.ObserveError('A_AreaAct_action');
        HostA.Close();
        HostB.OpenEdit();
        asserterror HostB.AreaAct.Invoke();
        Observer.ObserveError('B_AreaAct_action');
        HostB.Close();
        ApplicationArea(PreviousAreas);
        Observer.Expect('A_AreaFld_field|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('A_AreaFld_field|code', 'TestFieldNotFound');
        Observer.Expect('A_AreaPart_part|text', 'The part with ID = n was not found on the page.');
        Observer.Expect('A_AreaPart_part|code', 'TestPartNotFound');
        Observer.Expect('A_AreaAct_action|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('A_AreaAct_action|code', 'TestActionNotFound');
        Observer.Expect('B_AreaAct_action|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('B_AreaAct_action|code', 'TestActionNotFound');
        Observer.Verify();
    end;

    // md:119: GetField(Id) with the id of the not-found error, and a scan for the control ids that GetField does find on a page with three visible fields.
    [Test]
    procedure GetField_ByControlId()
    var
        Hidden: TestPage "W1 Hidden Host A";
        Pg: TestPage "W1 Visible Fields Card";
        Observer: Codeunit "Probe Observer";
        Flag: Boolean;
        Id: Integer;
        Found: Text;
        FoundCount: Integer;
        ValueText: Text;
        ErrorText: Text;
        IdText: Text;
        PreviousAreas: Text;
    begin
        SeedRows();
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic');
        Hidden.OpenEdit();
        asserterror Flag := Hidden.AreaFld.Visible();
        ErrorText := GetLastErrorText();
        ClearLastError();
        ApplicationArea(PreviousAreas);
        IdText := ErrorText.Replace('The field with ID = ', '').Replace(' is not found on the page.', '');
        Observer.Observe('error_text_shape', ErrorText.Replace(IdText, '<id>'));
        if Evaluate(Id, IdText) then begin
            Hidden.Close();
            Pg.OpenEdit();
            asserterror ValueText := Pg.GetField(Id).Value();
            Observer.ObserveError('getfield_with_id_of_hidden_field_of_other_page');
            Pg.Close();
        end else
            Hidden.Close();
        SeedRows();
        Pg.OpenEdit();
        for Id := 1 to 1500 do
            if TryGetFieldValue(Pg, Id, ValueText) then begin
                FoundCount += 1;
                if FoundCount <= 10 then
                    Found += Format(Id) + '=' + ValueText + ',';
            end;
        Observer.Observe('found_count', Format(FoundCount));
        Observer.Observe('found_first_ten', Found);
        asserterror ValueText := Pg.GetField(1).Value();
        Observer.ObserveError('getfield_1');
        asserterror ValueText := Pg.GetField(0).Value();
        Observer.ObserveError('getfield_0');
        asserterror ValueText := Pg.GetField(-1).Value();
        Observer.ObserveError('getfield_minus_1');
        Pg.Close();
        Observer.Expect('error_text_shape', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield_with_id_of_hidden_field_of_other_page|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield_with_id_of_hidden_field_of_other_page|code', 'TestFieldNotFound');
        Observer.Expect('found_count', '0');
        Observer.Expect('found_first_ten', '');
        Observer.Expect('getfield_1|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield_1|code', 'TestFieldNotFound');
        Observer.Expect('getfield_0|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield_0|code', 'TestFieldNotFound');
        Observer.Expect('getfield_minus_1|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('getfield_minus_1|code', 'TestFieldNotFound');
        Observer.Verify();
    end;
}
