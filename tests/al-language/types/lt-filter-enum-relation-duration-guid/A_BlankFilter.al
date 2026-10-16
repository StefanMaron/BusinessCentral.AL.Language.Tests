// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 72678, test codeunit 72679 (P85)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter(F, '') after SetRange / SetFilter on the same field, in filter group 0 and 2, FilterGroup restored: GetFilters, GetFilter, Count, HasFilter; format argument and FieldRef forms
// BC versions: 29 (27 and 28 by CI)

table 72678 "LT P85 Flt"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Num; Integer) { }
        field(4; Dec; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 72679 "LT P85 Blank Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P85 Flt";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Init();
            R.Id := i;
            R.Name := 'N' + Format(i);
            R.Num := i * 10;
            R.Dec := i / 2;
            R.Insert();
        end;
    end;

    local procedure Snap(var R: Record "LT P85 Flt"): Text
    begin
        exit(R.GetFilters() + '|' + R.GetFilter(Id) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
    end;

    [Test]
    procedure Blank_AfterSetRange_Group0()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Id, 1);
        Observer.Observe('before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('after', Snap(R));
        Observer.Observe('getfilters', R.GetFilters());
        Observer.Observe('getfilter', R.GetFilter(Id));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('hasfilter', Format(R.HasFilter()));
        Observer.Observe('getview', R.GetView());
        R.SetFilter(Id, '');
        Observer.Observe('again', Snap(R));
        R.SetRange(Id, 2);
        Observer.Observe('range_again', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('blank_again', Snap(R));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_AfterSetFilterGt_Group0()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetFilter(Id, '>1');
        Observer.Observe('before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('after', Snap(R));
        Observer.Observe('getview', R.GetView());
        R.SetFilter(Id, '>1');
        R.SetFilter(Id, '<>%1', 0);
        Observer.Observe('replaced', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('blank', Snap(R));
        R.SetFilter(Id, '2..3');
        Observer.Observe('range', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('blank2', Snap(R));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_Group2_AfterSetRange()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetRange(Id, 1);
        Observer.Observe('g2_before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('g2_after', Snap(R));
        Observer.Observe('g2_getfilter', R.GetFilter(Id));
        Observer.Observe('g2_count', Format(R.Count()));
        R.FilterGroup(0);
        Observer.Observe('g0', Snap(R));
        Observer.Observe('g0_hasfilter', Format(R.HasFilter()));
        Observer.Observe('group_now', Format(R.FilterGroup()));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_Group2_AfterSetFilterGt()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.FilterGroup(2);
        R.SetFilter(Id, '>1');
        Observer.Observe('g2_before', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('g2_after', Snap(R));
        R.FilterGroup(0);
        Observer.Observe('g0', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('g2_back', Snap(R));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_Group0_Filter_Group2_Blank()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
        OldGroup: Integer;
    begin
        Seed();
        R.SetRange(Id, 1);
        OldGroup := R.FilterGroup(2);
        Observer.Observe('old_group', Format(OldGroup));
        R.SetFilter(Id, '');
        Observer.Observe('g2_blank', Snap(R));
        R.FilterGroup(OldGroup);
        Observer.Observe('g0_after', Snap(R));
        Observer.Observe('g0_getfilters', R.GetFilters());
        R.FilterGroup(2);
        R.SetFilter(Id, '>2');
        Observer.Observe('g2_set', Snap(R));
        R.FilterGroup(0);
        Observer.Observe('g0_and', Snap(R));
        R.SetFilter(Id, '');
        Observer.Observe('g0_blank', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('g2_stays', Snap(R));
        R.FilterGroup(0);
        Observer.Finish();
    end;

    [Test]
    procedure Blank_Group_FilterGroup_Restored_Value()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
        Old: Integer;
    begin
        Seed();
        Old := R.FilterGroup(2);
        Observer.Observe('returns_old', Format(Old));
        Observer.Observe('now', Format(R.FilterGroup()));
        R.SetRange(Id, 3);
        R.FilterGroup(Old);
        Observer.Observe('restored', Format(R.FilterGroup()));
        R.SetFilter(Id, '');
        Observer.Observe('g0_blank_g2_kept', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('g2_view', R.GetView());
        R.FilterGroup(0);
        Observer.Observe('g0_view', R.GetView());
        R.Reset();
        Observer.Observe('reset', Snap(R));
        R.FilterGroup(2);
        Observer.Observe('reset_g2', Snap(R));
        R.FilterGroup(0);
        Observer.Finish();
    end;

    [Test]
    procedure Blank_OtherFieldKept()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Id, 1, 3);
        R.SetRange(Num, 20);
        R.SetFilter(Id, '');
        Observer.Observe('after', Snap(R));
        Observer.Observe('getfilter_num', R.GetFilter(Num));
        Observer.Observe('getfilters', R.GetFilters());
        R.SetFilter(Num, '');
        Observer.Observe('both_blank', Snap(R));
        Observer.Observe('hasfilter', Format(R.HasFilter()));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_TextAndDecimalFields()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Name, 'N1');
        R.SetFilter(Name, '');
        Observer.Observe('text_after_range', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetFilter(Name, '<>N1');
        R.SetFilter(Name, '');
        Observer.Observe('text_after_filter', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.Reset();
        R.SetRange(Dec, 1);
        R.SetFilter(Dec, '');
        Observer.Observe('dec_after_range', R.GetFilter(Dec) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetFilter(Dec, '>1');
        R.SetFilter(Dec, '');
        Observer.Observe('dec_after_filter', R.GetFilter(Dec) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetRange(Num, 10);
        R.SetFilter(Num, '');
        Observer.Observe('num_after_range', R.GetFilter(Num) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_FormatArgument()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
        Empty: Text;
        Zero: Integer;
    begin
        Seed();
        R.SetRange(Id, 1);
        R.SetFilter(Name, '%1', Empty);
        Observer.Observe('empty_text_arg', Snap(R));
        R.SetRange(Id, 1);
        R.SetFilter(Id, '%1', Zero);
        Observer.Observe('zero_arg', Snap(R));
        R.SetFilter(Id, '');
        R.SetRange(Name, 'N2');
        R.SetFilter(Name, '%1', '');
        Observer.Observe('name_empty_arg', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        R.SetFilter(Name, '%1|%2', '', 'N3');
        Observer.Observe('name_empty_or', R.GetFilter(Name) + '|' + Format(R.Count()));
        R.SetFilter(Name, ' ');
        Observer.Observe('name_space', R.GetFilter(Name) + '|' + Format(R.Count()) + '|' + Format(R.HasFilter()));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_SetRangeNoArguments()
    var
        R: Record "LT P85 Flt";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetRange(Id, 1);
        R.SetRange(Id);
        Observer.Observe('setrange_noargs', Snap(R));
        R.SetFilter(Id, '>1');
        R.SetRange(Id);
        Observer.Observe('setrange_noargs_after_filter', Snap(R));
        R.SetFilter(Id, '>1');
        R.SetFilter(Id, '');
        Observer.Observe('setfilter_blank', Snap(R));
        Observer.Finish();
    end;

    [Test]
    procedure Blank_FieldRef_SetFilter()
    var
        R: Record "LT P85 Flt";
        RRef: RecordRef;
        FRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RRef.Open(Database::"LT P85 Flt");
        FRef := RRef.Field(1);
        FRef.SetRange(1);
        Observer.Observe('range', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        FRef.SetFilter('');
        Observer.Observe('blank', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        FRef.SetFilter('>1');
        Observer.Observe('gt', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        FRef.SetFilter('');
        Observer.Observe('blank_gt', Format(RRef.Count()) + '|' + FRef.GetFilter() + '|' + Format(RRef.HasFilter()));
        RRef.FilterGroup(2);
        FRef.SetRange(2);
        RRef.FilterGroup(0);
        Observer.Observe('g2_set_g0_count', Format(RRef.Count()));
        RRef.FilterGroup(2);
        FRef.SetFilter('');
        Observer.Observe('g2_blank_count', Format(RRef.Count()) + '|' + Format(RRef.HasFilter()));
        RRef.FilterGroup(0);
        Observer.Observe('g0_count', Format(RRef.Count()) + '|' + Format(RRef.HasFilter()));
        RRef.Close();
        Observer.Finish();
    end;
}
