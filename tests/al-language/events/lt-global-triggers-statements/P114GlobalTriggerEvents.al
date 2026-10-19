// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 74239, SingleInstance log 74240 (used only by test codeunit 74244), subscribers 74241, pages 74242 and 74243
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: which platform business events of the codeunits "Company Triggers" (OnCompanyOpenCompleted), "UI Helper Triggers" (GetApplicationLanguage,
// AutoFormatTranslate, CaptionClassTranslate) and "Filter Helper Triggers" (MakeCodeFilter, MakeTextFilter, MakeIntFilter) fire while a test reads a page field with
// AutoFormatType / a CaptionClass, calls CaptionClassTranslate and sets filters (Record.SetFilter, TestPage Filter) on a Code field. The subscribers only log while the test
// has switched the log on and never change their var parameters. Which events fire is measured; nothing is assumed.
// OnCompanyOpenCompleted fires at session start, before a test can switch the log on: it is subscribed (compile and bind) but its count is not observed.

table 74239 "LT P114 Glob Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Code[20]) { }
        field(3; Descr; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; Cur; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74240 "LT P114 Glob Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        On: Boolean;

    procedure Start()
    begin
        Clear(Lines);
        On := true;
    end;

    procedure Stop()
    begin
        On := false;
    end;

    procedure Add(Line: Text)
    begin
        if On then
            Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure CountOf(Prefix: Text): Integer
    var
        Line: Text;
        N: Integer;
    begin
        foreach Line in Lines do
            if Line.StartsWith(Prefix) then
                N += 1;
        exit(N);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

codeunit 74241 "LT P114 Glob Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted()
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('OnCompanyOpenCompleted');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetApplicationLanguage', '', false, false)]
    local procedure GetApplicationLanguage(var Language: Integer)
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('GetApplicationLanguage');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'AutoFormatTranslate', '', false, false)]
    local procedure AutoFormatTranslate(AutoFormatType: Integer; AutoFormatExpr: Text[80]; var Translation: Text[80])
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('AutoFormatTranslate(type=' + Format(AutoFormatType) + ',expr=' + AutoFormatExpr + ',in=' + Translation + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'CaptionClassTranslate', '', false, false)]
    local procedure CaptionClassTranslate(Language: Integer; CaptionExpr: Text[1024]; var Translation: Text[1024])
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('CaptionClassTranslate(lang_is_session=' + Format(Language = GlobalLanguage()) + ',expr=' + CaptionExpr + ',in=' + Translation + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeCodeFilter', '', false, false)]
    local procedure MakeCodeFilter(var TextFilterText: Text)
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('MakeCodeFilter(' + TextFilterText + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeTextFilter', '', false, false)]
    local procedure MakeTextFilter(var TextFilterText: Text)
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('MakeTextFilter(' + TextFilterText + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Helper Triggers", 'MakeIntFilter', '', false, false)]
    local procedure MakeIntFilter(var IntFilterText: Text)
    var
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Add('MakeIntFilter(' + IntFilterText + ')');
    end;
}

page 74242 "LT P114 Glob List"
{
    PageType = List;
    SourceTable = "LT P114 Glob Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TagCtl; Rec.Tag) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
                field(CurrencyAmount; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec.Cur;
                }
                field(CustomAmount; Rec.Amount)
                {
                    ApplicationArea = All;
                    AutoFormatType = 11;
                    AutoFormatExpression = '<Precision,3:3><Standard Format,0>';
                }
            }
        }
    }
}

page 74243 "LT P114 Glob Card"
{
    PageType = Card;
    SourceTable = "LT P114 Glob Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ClaimedCaption; Rec.Descr)
            {
                ApplicationArea = All;
                CaptionClass = 'P114X,Hello';
            }
            field(AreaThree; Rec.Tag)
            {
                ApplicationArea = All;
                CaptionClass = '3,Plain caption';
            }
        }
    }
}

codeunit 74244 "LT P114 Global Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P114 Glob Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tag := 'ALPHA';
        Row.Descr := 'first';
        Row.Amount := 1234.5;
        Row.Cur := '';
        Row.Insert();
        Row.Id := 2;
        Row.Tag := 'BETA';
        Row.Descr := 'second';
        Row.Amount := 0.125;
        Row.Cur := 'XXX';
        Row.Insert();
    end;

    [Test]
    procedure P114_CodeFilterRecordSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Glob Log";
        Row: Record "LT P114 Glob Row";
    begin
        Seed();
        Log.Start();
        Row.SetFilter(Tag, 'A*');
        Observer.Observe('after-A-star', Log.Dump());
        Observer.Observe('filter', Row.GetFilter(Tag));
        Observer.Observe('count', Format(Row.Count()));
        Row.SetFilter(Tag, 'a*|b*');
        Observer.Observe('after-lower-or', Log.Dump());
        Row.SetFilter(Tag, '<>ALPHA');
        Row.SetFilter(Tag, '');
        Row.SetFilter(Id, '1..2');
        Observer.Observe('after-int-filter', Log.Dump());
        Row.SetFilter(Descr, 'f*');
        Observer.Observe('after-text-filter', Log.Dump());
        Log.Stop();
        Observer.Expect('after-A-star', '[]');
        Observer.Expect('filter', 'A*');
        Observer.Expect('count', '1');
        Observer.Expect('after-lower-or', '[]');
        Observer.Expect('after-int-filter', '[]');
        Observer.Expect('after-text-filter', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_CodeFilterTestPageFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Glob Log";
        List: TestPage "LT P114 Glob List";
    begin
        Seed();
        List.OpenView();
        Log.Start();
        List.Filter.SetFilter(Tag, 'A*');
        Observer.Observe('after-code-filter', Log.Dump());
        Observer.Observe('first-row-tag', List.TagCtl.Value());
        List.Filter.SetFilter(Descr, 'sec*');
        Observer.Observe('after-text-filter', Log.Dump());
        List.Filter.SetFilter(Id, '1');
        Observer.Observe('after-int-filter', Log.Dump());
        Log.Stop();
        List.Close();
        Observer.Expect('after-code-filter', '[]');
        Observer.Expect('first-row-tag', 'ALPHA');
        Observer.Expect('after-text-filter', '[]');
        Observer.Expect('after-int-filter', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_CaptionClassOnPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Glob Log";
        Card: TestPage "LT P114 Glob Card";
    begin
        Seed();
        Log.Start();
        Card.OpenView();
        Card.First();
        Observer.Observe('log-after-open', Log.Dump());
        Observer.Observe('claimed-caption', Card.ClaimedCaption.Caption());
        Observer.Observe('area3-caption', Card.AreaThree.Caption());
        Observer.Observe('log-after-captions', Log.Dump());
        Log.Stop();
        Card.Close();
        Observer.Expect('log-after-open', '[CaptionClassTranslate(lang_is_session=Yes,expr=P114X,Hello,in=P114X,Hello) | CaptionClassTranslate(lang_is_session=Yes,expr=3,Plain caption,in=Plain caption)]');
        Observer.Expect('claimed-caption', 'P114X,Hello');
        Observer.Expect('area3-caption', 'Plain caption');
        Observer.Expect('log-after-captions', '[CaptionClassTranslate(lang_is_session=Yes,expr=P114X,Hello,in=P114X,Hello) | CaptionClassTranslate(lang_is_session=Yes,expr=3,Plain caption,in=Plain caption)]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_CaptionClassTranslateCall()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Glob Log";
    begin
        Log.Start();
        Observer.Observe('area3', CaptionClassTranslate('3,Foo'));
        Observer.Observe('log-area3', Log.Dump());
        Observer.Observe('unclaimed', CaptionClassTranslate('P114ZZ,Foo'));
        Observer.Observe('log-unclaimed', Log.Dump());
        Observer.Observe('no-comma', CaptionClassTranslate('P114 no comma'));
        Observer.Observe('log-no-comma', Log.Dump());
        Log.Stop();
        Observer.Expect('area3', 'Foo');
        Observer.Expect('log-area3', '[CaptionClassTranslate(lang_is_session=Yes,expr=3,Foo,in=Foo)]');
        Observer.Expect('unclaimed', 'P114ZZ,Foo');
        Observer.Expect('log-unclaimed', '[CaptionClassTranslate(lang_is_session=Yes,expr=3,Foo,in=Foo) | CaptionClassTranslate(lang_is_session=Yes,expr=P114ZZ,Foo,in=P114ZZ,Foo)]');
        Observer.Expect('no-comma', 'P114 no comma');
        Observer.Expect('log-no-comma', '[CaptionClassTranslate(lang_is_session=Yes,expr=3,Foo,in=Foo) | CaptionClassTranslate(lang_is_session=Yes,expr=P114ZZ,Foo,in=P114ZZ,Foo) | CaptionClassTranslate(lang_is_session=Yes,expr=P114 no comma,in=P114 no comma)]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ApplicationLanguageReads()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Glob Log";
        Row: Record "LT P114 Glob Row";
        Txt: Text;
    begin
        Seed();
        Log.Start();
        Row.FindFirst();
        Txt := Format(Row.Amount);
        Txt := Format(Today(), 0, 4);
        Txt := Format(Row.Amount, 0, '<Precision,2:2><Standard Format,0>');
        Observer.Observe('log-after-format', Log.Dump());
        Observer.Observe('count', Format(Log.CountOf('GetApplicationLanguage')));
        Log.Stop();
        Observer.Expect('log-after-format', '[]');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;
    // Writer PW: trust-refusals probe list "CaptionClassTranslate arguments and result": what a subscriber that sets Translation changes (the
    // LT P114 Glob Subs subscribers never change it). LT PW CCT Subs sets Translation to 'T[' + CaptionExpr + ']' in mode set, to '' in mode
    // blank, and counts its calls. Only results and counts are observed (the order of the two subscribers is not).
    local procedure PwTranslate(Mode: Text): Text
    var
        Subs: Codeunit "LT PW CCT Subs";
        R: Text;
    begin
        Subs.SetMode(Mode);
        R := 'area3=' + CaptionClassTranslate('3,Foo') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | unclaimed=' + CaptionClassTranslate('P114ZZ,Foo') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | noComma=' + CaptionClassTranslate('P114 no comma') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | empty=' + CaptionClassTranslate('') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | area3Empty=' + CaptionClassTranslate('3,') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | leadingComma=' + CaptionClassTranslate(',Foo') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | area1=' + CaptionClassTranslate('1,1,1') + ' calls=' + Format(Subs.TakeCalls());
        R += ' | lastSeen=' + Subs.LastSeen();
        Subs.SetMode('');
        exit(R);
    end;

    [Test]
    procedure PW_CaptionClassTranslate_SubscriberSetsTranslation()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('set', PwTranslate('set'));
        Observer.Observe('blank', PwTranslate('blank'));
        Observer.Observe('keep', PwTranslate('keep'));
        Observer.Finish();
    end;

    [Test]
    procedure PW_CaptionClassTranslate_SubscriberSetsTranslation_OnPage()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT PW CCT Subs";
        Card: TestPage "LT P114 Glob Card";
    begin
        Seed();
        Subs.SetMode('set');
        Card.OpenView();
        Card.First();
        Observer.Observe('calls after open', Format(Subs.TakeCalls()));
        Observer.Observe('claimed caption', Card.ClaimedCaption.Caption());
        Observer.Observe('area3 caption', Card.AreaThree.Caption());
        Observer.Observe('calls after captions', Format(Subs.TakeCalls()));
        Card.Close();
        Subs.SetMode('blank');
        Card.OpenView();
        Card.First();
        Observer.Observe('blank claimed caption', Card.ClaimedCaption.Caption());
        Observer.Observe('blank area3 caption', Card.AreaThree.Caption());
        Card.Close();
        Subs.SetMode('');
        Observer.Finish();
    end;
}

codeunit 86149 "LT PW CCT Subs"
{
    SingleInstance = true;

    var
        Mode: Text;
        Calls: Integer;
        Seen: Text;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
        Calls := 0;
        Seen := '';
    end;

    procedure TakeCalls(): Integer
    var
        N: Integer;
    begin
        N := Calls;
        Calls := 0;
        exit(N);
    end;

    procedure LastSeen(): Text
    begin
        exit(Seen);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'CaptionClassTranslate', '', false, false)]
    local procedure PwCaptionClassTranslate(Language: Integer; CaptionExpr: Text[1024]; var Translation: Text[1024])
    begin
        if Mode = '' then
            exit;
        Calls += 1;
        Seen := 'lang_is_session=' + Format(Language = GlobalLanguage()) + ',expr=' + CaptionExpr;
        case Mode of
            'set':
                Translation := 'T[' + CaptionExpr + ']';
            'blank':
                Translation := '';
        end;
    end;
}
