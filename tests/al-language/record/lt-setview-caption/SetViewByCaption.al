// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67169 "LT SV Caption"
// Probe: SetView and GetView where a field's Caption differs from its name. Field "Line No." has the caption 'Primary Key'; field Alpha has the caption 'Beta'
// and field Beta has the caption 'Gamma' (a caption equal to another field's name). SetView(GetView()) after SetRange, SetView with the caption in WHERE and
// SORTING, GetView(false), and which field a name that is also a caption selects. Settles: set-view-field-by-caption. Object ids 67169 - 67170.

table 67169 "LT SV Caption"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { Caption = 'Primary Key'; }
        field(2; Alpha; Integer) { Caption = 'Beta'; }
        field(3; Beta; Integer) { Caption = 'Gamma'; }
        field(4; Note; Code[10]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
        key(ByAlpha; Alpha) { }
    }
}

codeunit 67170 "LT SV Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT SV Caption";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Init();
            Row."Line No." := Index;
            Row.Alpha := Index * 10;
            Row.Beta := 5 - Index;
            Row.Note := 'N' + Format(Index);
            Row.Insert();
        end;
    end;

    local procedure Ids(var Row: Record "LT SV Caption"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row."Line No.") + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetView(var Row: Record "LT SV Caption"; View: Text)
    begin
        Row.SetView(View);
    end;

    local procedure ViewOutcome(View: Text): Text
    var
        Row: Record "LT SV Caption";
    begin
        ClearLastError();
        if not TrySetView(Row, View) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok:view=' + Row.GetView() + '|plain=' + Row.GetView(false) + '|filters=' + Row.GetFilters() + '|ids=' + Ids(Row));
    end;

    [Test]
    procedure GetView_UsesCaptionsOrNames()
    var
        Row: Record "LT SV Caption";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange("Line No.", 2);
        Observer.Observe('line_no_view', Row.GetView());
        Observer.Observe('line_no_view_plain', Row.GetView(false));
        Observer.Observe('line_no_filters', Row.GetFilters());
        Row.Reset();
        Row.SetRange(Alpha, 20);
        Observer.Observe('alpha_view', Row.GetView());
        Observer.Observe('alpha_view_plain', Row.GetView(false));
        Row.Reset();
        Row.SetRange(Beta, 3);
        Observer.Observe('beta_view', Row.GetView());
        Observer.Observe('beta_view_plain', Row.GetView(false));
        Row.Reset();
        Row.SetCurrentKey(Alpha);
        Observer.Observe('sorting_view', Row.GetView());
        Observer.Observe('sorting_view_plain', Row.GetView(false));
        Observer.Finish();
    end;

    [Test]
    procedure SetView_RoundTripOfGetView()
    var
        Row: Record "LT SV Caption";
        Other: Record "LT SV Caption";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange("Line No.", 2, 3);
        Row.SetRange(Beta, 2, 3);
        Other.SetView(Row.GetView());
        Observer.Observe('round_trip_view', Other.GetView());
        Observer.Observe('round_trip_ids', Ids(Other));
        Other.Reset();
        Other.SetView(Row.GetView(false));
        Observer.Observe('round_trip_plain_view', Other.GetView());
        Observer.Observe('round_trip_plain_ids', Ids(Other));
        Observer.Finish();
    end;

    [Test]
    procedure SetView_CaptionInWhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('name_line_no', ViewOutcome('WHERE("Line No."=FILTER(2))'));
        Observer.Observe('caption_primary_key', ViewOutcome('WHERE(Primary Key=FILTER(2))'));
        Observer.Observe('caption_primary_key_quoted', ViewOutcome('WHERE("Primary Key"=FILTER(2))'));
        Observer.Observe('caption_gamma', ViewOutcome('WHERE(Gamma=FILTER(3))'));
        Observer.Observe('name_alpha', ViewOutcome('WHERE(Alpha=FILTER(20))'));
        Observer.Observe('name_beta_is_also_a_caption', ViewOutcome('WHERE(Beta=FILTER(20))'));
        Observer.Observe('name_beta_value_3', ViewOutcome('WHERE(Beta=FILTER(3))'));
        Observer.Finish();
    end;

    [Test]
    procedure SetView_CaptionInSorting()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('sorting_name', ViewOutcome('SORTING(Alpha)'));
        Observer.Observe('sorting_caption_of_alpha', ViewOutcome('SORTING(Beta)'));
        Observer.Observe('sorting_caption_primary_key', ViewOutcome('SORTING(Primary Key)'));
        Observer.Observe('sorting_and_where_caption', ViewOutcome('SORTING(Primary Key) WHERE(Primary Key=FILTER(2..3))'));
        Observer.Finish();
    end;
}
