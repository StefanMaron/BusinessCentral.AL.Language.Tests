// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); P137Fix.al (tables 74415, 74416, codeunit 74417)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.SetSelectionFilter(Record) when the record handed in already has filters (a range on another field, on the key, a text filter, a different current key, descending order, marks, MarkedOnly, field values set, filters followed by Reset): the filters, view, field values and rows afterwards
// BC versions: 29 (27 and 28 by CI)

page 74434 "LT P137 Sel List"
{
    PageType = List;
    SourceTable = "LT P137 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Ctl: Codeunit "LT P137 Ctl";
                    Dst: Record "LT P137 Row";
                begin
                    case Ctl.Mode() of
                        'range-qty':
                            Dst.SetRange(Qty, 20, 30);
                        'range-id':
                            Dst.SetRange(Id, 1, 3);
                        'range-id-same-key':
                            Dst.SetRange(Id, 2, 4);
                        'filter-name':
                            Dst.SetFilter(Name, 'a*|b*');
                        'key':
                            Dst.SetCurrentKey(Name);
                        'desc':
                            Dst.Ascending(false);
                        'mark':
                            begin
                                Dst.Get(1);
                                Dst.Mark(true);
                            end;
                        'markedonly':
                            begin
                                Dst.Get(1);
                                Dst.Mark(true);
                                Dst.MarkedOnly(true);
                            end;
                        'values':
                            begin
                                Dst.Id := 3;
                                Dst.Name := 'zzz';
                            end;
                        'reset-after':
                            begin
                                Dst.SetRange(Qty, 20, 30);
                                Dst.Reset();
                            end;
                        'twice':
                            begin
                                CurrPage.SetSelectionFilter(Dst);
                                Ctl.Add('first filters=[' + Dst.GetFilters() + ']');
                            end;
                    end;
                    CurrPage.SetSelectionFilter(Dst);
                    Ctl.Add(Ctl.Mode() + ' filters=[' + Dst.GetFilters() + '] view=[' + Dst.GetView() + '] id=' + Format(Dst.Id) + ' count=' + Format(Dst.Count()) + ' first=' + FirstId(Dst));
                end;
            }
        }
    }

    local procedure FirstId(var Dst: Record "LT P137 Row"): Text
    begin
        if Dst.FindFirst() then
            exit(Format(Dst.Id));
        exit('none');
    end;
}

codeunit 74435 "LT P137 Sel Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P137 Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Name := CopyStr('abcd', I, 1);
            Row.Qty := I * 10;
            Row.Insert();
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Ctl: Codeunit "LT P137 Ctl";
        List: TestPage "LT P137 Sel List";
    begin
        Ctl.Take();
        Ctl.SetMode(Mode);
        List.OpenView();
        List.GoToKey(2);
        List.SelFilter.Invoke();
        List.Close();
        Observer.Observe('mode_' + Mode, CopyStr(Ctl.Take(), 1, 850));
        Ctl.SetMode('');
    end;

    [Test]
    procedure P137_SetSelectionFilter_IntoAFilteredRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'plain');
        Probe(Observer, 'range-qty');
        Probe(Observer, 'range-id');
        Probe(Observer, 'range-id-same-key');
        Probe(Observer, 'filter-name');
        Probe(Observer, 'reset-after');
        Probe(Observer, 'twice');
        Observer.Expect('mode_plain', 'plain filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_range-qty', 'range-qty filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_range-id', 'range-id filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_range-id-same-key', 'range-id-same-key filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_filter-name', 'filter-name filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_reset-after', 'reset-after filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_twice', 'first filters=[Id: 2];twice filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Verify();
    end;

    [Test]
    procedure P137_SetSelectionFilter_IntoARecordWithKeyMarksOrValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'key');
        Probe(Observer, 'desc');
        Probe(Observer, 'mark');
        Probe(Observer, 'markedonly');
        Probe(Observer, 'values');
        Observer.Expect('mode_key', 'key filters=[Id: 2] view=[VERSION(1) SORTING(Name) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_desc', 'desc filters=[Id: 2] view=[VERSION(1) SORTING(Id) ORDER(Descending) WHERE(Id=FILTER(2))] id=0 count=1 first=2;');
        Observer.Expect('mode_mark', 'mark filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=1 count=1 first=2;');
        Observer.Expect('mode_markedonly', 'markedonly filters=[Marked: Yes, Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=1 count=1 first=2;');
        Observer.Expect('mode_values', 'values filters=[Id: 2] view=[VERSION(1) SORTING(Id) WHERE(Id=FILTER(2))] id=3 count=1 first=2;');
        Observer.Verify();
    end;
}
