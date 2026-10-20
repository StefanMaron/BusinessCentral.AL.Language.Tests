// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-pages-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QcFindViewObjects.al (86440 to 86448).
// Probe: writer QC, for the al-runtime-rs refusal "OnFindRecord on a page whose SourceTableView filters". Written against a local BC 29.0
//   service tier; every literal below is what that tier produced; 27.5 and 28.5 by the CI matrix.
// BC versions: 27, 28, 29

codeunit 86441 "LT QC Find View Tests"
{
    Subtype = Test;

    local procedure Seed()
    var
        Row: Record "LT QC Find Row";
        Head: Record "LT QC Find Head";
        Line: Record "LT QC Find Line";
        Log: Codeunit "LT QC Find Log";
        I: Integer;
    begin
        Row.DeleteAll();
        Head.DeleteAll();
        Line.DeleteAll();
        for I := 1 to 6 do begin
            Row.Init();
            Row.Id := I;
            if I mod 2 = 0 then
                Row.Kind := Row.Kind::B
            else
                Row.Kind := Row.Kind::A;
            Row.Insert();
        end;
        Head."No." := 'H1';
        Head.Insert();
        Head."No." := 'H2';
        Head.Insert();
        AddLine(Line."Doc Kind"::A, 'H1', 10000);
        AddLine(Line."Doc Kind"::A, 'H1', 20000);
        AddLine(Line."Doc Kind"::B, 'H1', 15000);
        AddLine(Line."Doc Kind"::A, 'H2', 30000);
        AddLine(Line."Doc Kind"::B, 'H2', 40000);
        Log.Take();
        Log.TakeFilters();
    end;

    local procedure AddLine(Kind: Enum "LT QC Find Kind"; DocNo: Code[20]; LineNo: Integer)
    var
        Line: Record "LT QC Find Line";
    begin
        Line."Doc Kind" := Kind;
        Line."Doc No." := DocNo;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure Cut(Value: Text): Text
    begin
        exit(CopyStr(Value, 1, 400));
    end;

    // ---------------------------------------------------------------- list, OnFindRecord only

    [Test]
    procedure ViewList_OpenView_FindStringAndRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find View List";
    begin
        Seed();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        L.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ViewList_FirstNextLastPrevious()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find View List";
        Ids: Text;
        I: Integer;
    begin
        Seed();
        L.OpenView();
        Log.Take();
        Observer.Observe('first', Format(L.First()) + ':' + L.Id.Value());
        Observer.Observe('first_log', Cut(Log.Take()));
        Ids := L.Id.Value();
        I := 0;
        while L.Next() and (I < 10) do begin
            Ids += ',' + L.Id.Value();
            I += 1;
        end;
        Observer.Observe('walk', Ids);
        Observer.Observe('walk_log', Cut(Log.Take()));
        Observer.Observe('last', Format(L.Last()) + ':' + L.Id.Value());
        Observer.Observe('last_log', Cut(Log.Take()));
        Observer.Observe('previous', Format(L.Previous()) + ':' + L.Id.Value());
        Observer.Observe('previous_log', Cut(Log.Take()));
        L.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ViewList_GoToKey()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find View List";
    begin
        Seed();
        L.OpenView();
        Log.Take();
        Observer.Observe('gotokey_2', Format(L.GoToKey(2)) + ':' + L.Id.Value());
        Observer.Observe('gotokey_2_log', Cut(Log.Take()));
        Observer.Observe('gotokey_5', Format(L.GoToKey(5)) + ':' + L.Id.Value());
        Observer.Observe('gotokey_5_log', Cut(Log.Take()));
        L.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ViewList_PageRunOnFilteredOutRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        Row: Record "LT QC Find Row";
        L: TestPage "LT QC Find View List";
    begin
        Seed();
        Row.Get(4);
        L.Trap();
        Page.Run(Page::"LT QC Find View List", Row);
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        L.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ViewList_PageRunOnRowInView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        Row: Record "LT QC Find Row";
        L: TestPage "LT QC Find View List";
    begin
        Seed();
        Row.Get(3);
        L.Trap();
        Page.Run(Page::"LT QC Find View List", Row);
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        L.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- list, OnFindRecord and OnNextRecord

    [Test]
    procedure NextList_OpenAndWalk()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find Next List";
        Ids: Text;
        I: Integer;
    begin
        Seed();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        Observer.Observe('first', Format(L.First()) + ':' + L.Id.Value());
        Ids := L.Id.Value();
        I := 0;
        while L.Next() and (I < 10) do begin
            Ids += ',' + L.Id.Value();
            I += 1;
        end;
        Observer.Observe('walk', Ids);
        Observer.Observe('last', Format(L.Last()) + ':' + L.Id.Value());
        Observer.Observe('gotokey_4', Format(L.GoToKey(4)) + ':' + L.Id.Value());
        L.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NextList_NextLog()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find Next List";
    begin
        Seed();
        L.OpenView();
        L.First();
        Log.Take();
        Observer.Observe('next', Format(L.Next()) + ':' + L.Id.Value());
        Observer.Observe('next_log', Cut(Log.Take()));
        L.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- list, sorting + descending + WHERE

    [Test]
    procedure DescList_OpenAndWalk()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find Desc List";
        Ids: Text;
        I: Integer;
    begin
        Seed();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        Observer.Observe('first', Format(L.First()) + ':' + L.Id.Value());
        Ids := L.Id.Value();
        I := 0;
        while L.Next() and (I < 10) do begin
            Ids += ',' + L.Id.Value();
            I += 1;
        end;
        Observer.Observe('walk', Ids);
        Observer.Observe('last', Format(L.Last()) + ':' + L.Id.Value());
        Observer.Observe('gotokey_2', Format(L.GoToKey(2)) + ':' + L.Id.Value());
        L.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- list, triggers serve rows outside the view

    [Test]
    procedure FreeList_OpenAndWalk()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        L: TestPage "LT QC Find Free List";
        Ids: Text;
        I: Integer;
    begin
        Seed();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('first', Format(L.First()) + ':' + L.Id.Value());
        Ids := L.Id.Value();
        I := 0;
        while L.Next() and (I < 10) do begin
            Ids += ',' + L.Id.Value();
            I += 1;
        end;
        Observer.Observe('walk', Ids);
        Observer.Observe('last', Format(L.Last()) + ':' + L.Id.Value());
        Observer.Observe('gotokey_2', Format(L.GoToKey(2)) + ':' + L.Id.Value());
        L.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- list, same view, no triggers (control arm)

    [Test]
    procedure PlainList_OpenAndWalk()
    var
        Observer: Codeunit "Probe Observer";
        L: TestPage "LT QC Find Plain List";
        Ids: Text;
        I: Integer;
    begin
        Seed();
        L.OpenView();
        Observer.Observe('current', L.Id.Value());
        Observer.Observe('first', Format(L.First()) + ':' + L.Id.Value());
        Ids := L.Id.Value();
        I := 0;
        while L.Next() and (I < 10) do begin
            Ids += ',' + L.Id.Value();
            I += 1;
        end;
        Observer.Observe('walk', Ids);
        Observer.Observe('last', Format(L.Last()) + ':' + L.Id.Value());
        Observer.Observe('gotokey_2', Format(L.GoToKey(2)) + ':' + L.Id.Value());
        L.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- card

    [Test]
    procedure ViewCard_OpenView_FindStringAndRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        C: TestPage "LT QC Find View Card";
    begin
        Seed();
        C.OpenView();
        Observer.Observe('current', C.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        C.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ViewCard_Navigate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        C: TestPage "LT QC Find View Card";
    begin
        Seed();
        C.OpenView();
        Log.Take();
        Observer.Observe('next', Format(C.Next()) + ':' + C.Id.Value());
        Observer.Observe('next_log', Cut(Log.Take()));
        Observer.Observe('last', Format(C.Last()) + ':' + C.Id.Value());
        Observer.Observe('last_log', Cut(Log.Take()));
        Observer.Observe('previous', Format(C.Previous()) + ':' + C.Id.Value());
        Observer.Observe('first', Format(C.First()) + ':' + C.Id.Value());
        Observer.Observe('gotokey_2', Format(C.GoToKey(2)) + ':' + C.Id.Value());
        Observer.Observe('gotokey_5', Format(C.GoToKey(5)) + ':' + C.Id.Value());
        Observer.Observe('gotokey_log', Cut(Log.Take()));
        C.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ViewCard_PageRunOnFilteredOutRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        Row: Record "LT QC Find Row";
        C: TestPage "LT QC Find View Card";
    begin
        Seed();
        Row.Get(4);
        C.Trap();
        Page.Run(Page::"LT QC Find View Card", Row);
        Observer.Observe('current', C.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        C.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- document card with the Service Invoice fallback

    [Test]
    procedure FallbackCard_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        C: TestPage "LT QC Find Fallback Card";
    begin
        Seed();
        C.OpenView();
        Observer.Observe('current', C.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('next', Format(C.Next()) + ':' + C.Id.Value());
        Observer.Observe('gotokey_4', Format(C.GoToKey(4)) + ':' + C.Id.Value());
        C.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FallbackCard_KeyFilterOnFilteredOutRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        Row: Record "LT QC Find Row";
        C: TestPage "LT QC Find Fallback Card";
    begin
        Seed();
        Row.SetRange(Id, 4);
        Row.FindFirst();
        C.Trap();
        Page.Run(Page::"LT QC Find Fallback Card", Row);
        Observer.Observe('current', C.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('open_filters', Log.TakeFilters());
        C.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FallbackCard_KeyFilterOnRowInView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        Row: Record "LT QC Find Row";
        C: TestPage "LT QC Find Fallback Card";
    begin
        Seed();
        Row.SetRange(Id, 3);
        Row.FindFirst();
        C.Trap();
        Page.Run(Page::"LT QC Find Fallback Card", Row);
        Observer.Observe('current', C.Id.Value());
        Observer.Observe('open_log', Cut(Log.Take()));
        Observer.Observe('next', Format(C.Next()) + ':' + C.Id.Value());
        C.Close();
        Observer.Finish();
    end;

    // ---------------------------------------------------------------- document with a subform part (Sales Order Subform shape)

    [Test]
    procedure DocPart_OpenEdit_LinesOfH1()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        D: TestPage "LT QC Find Doc";
        Lines: Text;
        I: Integer;
    begin
        Seed();
        D.OpenEdit();
        Observer.Observe('gotokey_h1', Format(D.GoToKey('H1')));
        Observer.Observe('part_current', D.LinesPart."Line No.".Value());
        Observer.Observe('part_log', Cut(Log.Take()));
        Observer.Observe('part_filters', Log.TakeFilters());
        Observer.Observe('part_first', Format(D.LinesPart.First()) + ':' + D.LinesPart."Line No.".Value());
        Lines := D.LinesPart."Line No.".Value();
        I := 0;
        while D.LinesPart.Next() and (I < 10) do begin
            Lines += ',' + D.LinesPart."Line No.".Value();
            I += 1;
        end;
        Observer.Observe('part_walk', Lines);
        Observer.Observe('part_last', Format(D.LinesPart.Last()) + ':' + D.LinesPart."Line No.".Value());
        D.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DocPart_OpenEdit_LinesOfH2()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        D: TestPage "LT QC Find Doc";
        Lines: Text;
        I: Integer;
    begin
        Seed();
        D.OpenEdit();
        D.GoToKey('H2');
        Log.Take();
        Log.TakeFilters();
        Observer.Observe('part_first', Format(D.LinesPart.First()) + ':' + D.LinesPart."Line No.".Value());
        Lines := D.LinesPart."Line No.".Value();
        I := 0;
        while D.LinesPart.Next() and (I < 10) do begin
            Lines += ',' + D.LinesPart."Line No.".Value();
            I += 1;
        end;
        Observer.Observe('part_walk', Lines);
        Observer.Observe('part_walk_log', Cut(Log.Take()));
        D.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DocPart_PageRunOnRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QC Find Log";
        Head: Record "LT QC Find Head";
        D: TestPage "LT QC Find Doc";
    begin
        Seed();
        Head.Get('H1');
        D.Trap();
        Page.Run(Page::"LT QC Find Doc", Head);
        Observer.Observe('no', D."No.".Value());
        Observer.Observe('part_current', D.LinesPart."Line No.".Value());
        Observer.Observe('part_log', Cut(Log.Take()));
        Observer.Observe('part_filters', Log.TakeFilters());
        D.Close();
        Observer.Finish();
    end;
}
