// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/format/format-function
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enum 74268, table 74269, pages 74270 and 74271, codeunit 74272
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reason 17): "Format of a TestPage control (standard format N) is not pinned yet" (Format(TestPage.Field) of a Decimal control: `Assert.AreEqual('10', Format(DeferralTemplateList."Deferral %"))`).
// Facts: Format(<TestPage field>) without .Value on a card and on a list page, for every field type (Text, Code, Integer, BigInteger, Decimal, Boolean, Date, Time, DateTime, Duration, Option, Enum), blank and filled rows, a Decimal with and without DecimalPlaces, BlankZero; next to the control's own Value text; with standard format 9, with a length and through StrSubstNo.
// BC versions: 29 (27 and 28 by CI)

enum 74268 "LT P135 Fmt Enum"
{
    Extensible = true;

    value(0; First)
    {
        Caption = 'First Cap';
    }
    value(1; Second)
    {
        Caption = 'Second Cap';
    }
}

table 74269 "LT P135 Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cd; Code[10]) { }
        field(4; Int; Integer) { }
        field(5; Big; BigInteger) { }
        field(6; Dec; Decimal) { }
        field(7; Bool; Boolean) { }
        field(8; Dt; Date) { }
        field(9; Tm; Time) { }
        field(10; Dtm; DateTime) { }
        field(11; Dur; Duration) { }
        field(12; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(13; En; Enum "LT P135 Fmt Enum") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 74270 "LT P135 Fmt Card"
{
    PageType = Card;
    SourceTable = "LT P135 Fmt Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TxtCtl; Rec.Txt)
                {
                    ApplicationArea = All;
                }
                field(CdCtl; Rec.Cd)
                {
                    ApplicationArea = All;
                }
                field(IntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                }
                field(BigCtl; Rec.Big)
                {
                    ApplicationArea = All;
                }
                field(DecCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                }
                field(DecPlacesCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                }
                field(BoolCtl; Rec.Bool)
                {
                    ApplicationArea = All;
                }
                field(DtCtl; Rec.Dt)
                {
                    ApplicationArea = All;
                }
                field(TmCtl; Rec.Tm)
                {
                    ApplicationArea = All;
                }
                field(DtmCtl; Rec.Dtm)
                {
                    ApplicationArea = All;
                }
                field(DurCtl; Rec.Dur)
                {
                    ApplicationArea = All;
                }
                field(OptCtl; Rec.Opt)
                {
                    ApplicationArea = All;
                }
                field(EnCtl; Rec.En)
                {
                    ApplicationArea = All;
                }
                field(BlankIntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
            }
        }
    }
}

page 74271 "LT P135 Fmt List"
{
    PageType = List;
    SourceTable = "LT P135 Fmt Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TxtCtl; Rec.Txt)
                {
                    ApplicationArea = All;
                }
                field(CdCtl; Rec.Cd)
                {
                    ApplicationArea = All;
                }
                field(IntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                }
                field(BigCtl; Rec.Big)
                {
                    ApplicationArea = All;
                }
                field(DecCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                }
                field(DecPlacesCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                }
                field(BoolCtl; Rec.Bool)
                {
                    ApplicationArea = All;
                }
                field(DtCtl; Rec.Dt)
                {
                    ApplicationArea = All;
                }
                field(TmCtl; Rec.Tm)
                {
                    ApplicationArea = All;
                }
                field(DtmCtl; Rec.Dtm)
                {
                    ApplicationArea = All;
                }
                field(DurCtl; Rec.Dur)
                {
                    ApplicationArea = All;
                }
                field(OptCtl; Rec.Opt)
                {
                    ApplicationArea = All;
                }
                field(EnCtl; Rec.En)
                {
                    ApplicationArea = All;
                }
                field(BlankIntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
            }
        }
    }
}

codeunit 74272 "LT P135 Fmt TestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(Id: Integer; Dec: Decimal)
    var
        R: Record "LT P135 Fmt Row";
    begin
        R.Init();
        R.Id := Id;
        R.Dec := Dec;
        R.Insert();
    end;

    local procedure Seed()
    var
        R: Record "LT P135 Fmt Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Txt := 'Hello';
        R.Cd := 'abc';
        R.Int := 1234567;
        R.Big := 2147483647;
        R.Big := R.Big * 2;
        R.Dec := 1234.5;
        R.Bool := true;
        R.Dt := 20240302D;
        R.Tm := 123456T;
        R.Dtm := CreateDateTime(20240302D, 123456T);
        R.Dur := 3723000;
        R.Opt := R.Opt::One;
        R.En := R.En::Second;
        R.Insert();
        Add(2, 0);
        Add(3, 10);
        Add(4, 10.5);
        Add(5, 0.5);
        Add(6, -5.5);
        Add(7, 1234567.891);
        Add(8, 100000);
    end;

    [Test]
    procedure P135_Card_FilledRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P135 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey(1);
        Observer.Observe('txtctl', Format(Card.TxtCtl) + '|' + Format(Card.TxtCtl.Value));
        Observer.Observe('cdctl', Format(Card.CdCtl) + '|' + Format(Card.CdCtl.Value));
        Observer.Observe('intctl', Format(Card.IntCtl) + '|' + Format(Card.IntCtl.Value));
        Observer.Observe('bigctl', Format(Card.BigCtl) + '|' + Format(Card.BigCtl.Value));
        Observer.Observe('decctl', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value));
        Observer.Observe('decplacesctl', Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Observer.Observe('boolctl', Format(Card.BoolCtl) + '|' + Format(Card.BoolCtl.Value));
        Observer.Observe('dtctl', Format(Card.DtCtl) + '|' + Format(Card.DtCtl.Value));
        Observer.Observe('tmctl', Format(Card.TmCtl) + '|' + Format(Card.TmCtl.Value));
        Observer.Observe('dtmctl', Format(Card.DtmCtl) + '|' + Format(Card.DtmCtl.Value));
        Observer.Observe('durctl', Format(Card.DurCtl) + '|' + Format(Card.DurCtl.Value));
        Observer.Observe('optctl', Format(Card.OptCtl) + '|' + Format(Card.OptCtl.Value));
        Observer.Observe('enctl', Format(Card.EnCtl) + '|' + Format(Card.EnCtl.Value));
        Observer.Observe('blankintctl', Format(Card.BlankIntCtl) + '|' + Format(Card.BlankIntCtl.Value));
        Card.Close();
        Observer.Expect('txtctl', 'Hello|Hello');
        Observer.Expect('cdctl', 'ABC|ABC');
        Observer.Expect('intctl', '1234567|1234567');
        Observer.Expect('bigctl', '4294967294|4294967294');
        Observer.Expect('decctl', '1,234.50|1,234.50');
        Observer.Expect('decplacesctl', '1,234.50|1,234.50');
        Observer.Expect('boolctl', 'Yes|Yes');
        Observer.Expect('dtctl', '3/2/2024|3/2/2024');
        Observer.Expect('tmctl', '12:34:56 PM|12:34:56 PM');
        Observer.Expect('dtmctl', '3/2/2024 12:34 PM|3/2/2024 12:34 PM');
        Observer.Expect('durctl', '1 hour 2 minutes 3 seconds|1 hour 2 minutes 3 seconds');
        Observer.Expect('optctl', 'One|One');
        Observer.Expect('enctl', 'Second Cap|Second Cap');
        Observer.Expect('blankintctl', '1234567|1234567');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Card_BlankRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P135 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey(2);
        Observer.Observe('txtctl', Format(Card.TxtCtl) + '|' + Format(Card.TxtCtl.Value));
        Observer.Observe('cdctl', Format(Card.CdCtl) + '|' + Format(Card.CdCtl.Value));
        Observer.Observe('intctl', Format(Card.IntCtl) + '|' + Format(Card.IntCtl.Value));
        Observer.Observe('bigctl', Format(Card.BigCtl) + '|' + Format(Card.BigCtl.Value));
        Observer.Observe('decctl', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value));
        Observer.Observe('decplacesctl', Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Observer.Observe('boolctl', Format(Card.BoolCtl) + '|' + Format(Card.BoolCtl.Value));
        Observer.Observe('dtctl', Format(Card.DtCtl) + '|' + Format(Card.DtCtl.Value));
        Observer.Observe('tmctl', Format(Card.TmCtl) + '|' + Format(Card.TmCtl.Value));
        Observer.Observe('dtmctl', Format(Card.DtmCtl) + '|' + Format(Card.DtmCtl.Value));
        Observer.Observe('durctl', Format(Card.DurCtl) + '|' + Format(Card.DurCtl.Value));
        Observer.Observe('optctl', Format(Card.OptCtl) + '|' + Format(Card.OptCtl.Value));
        Observer.Observe('enctl', Format(Card.EnCtl) + '|' + Format(Card.EnCtl.Value));
        Observer.Observe('blankintctl', Format(Card.BlankIntCtl) + '|' + Format(Card.BlankIntCtl.Value));
        Card.Close();
        Observer.Expect('txtctl', '|');
        Observer.Expect('cdctl', '|');
        Observer.Expect('intctl', '0|0');
        Observer.Expect('bigctl', '0|0');
        Observer.Expect('decctl', '0.00|0.00');
        Observer.Expect('decplacesctl', '0.00|0.00');
        Observer.Expect('boolctl', 'No|No');
        Observer.Expect('dtctl', '|');
        Observer.Expect('tmctl', '|');
        Observer.Expect('dtmctl', '|');
        Observer.Expect('durctl', '|');
        Observer.Expect('optctl', 'Zero|Zero');
        Observer.Expect('enctl', 'First Cap|First Cap');
        Observer.Expect('blankintctl', '|');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Card_Decimals()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P135 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey(3);
        Observer.Observe('ten', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.GoToKey(4);
        Observer.Observe('ten and a half', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.GoToKey(5);
        Observer.Observe('half', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.GoToKey(6);
        Observer.Observe('negative', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.GoToKey(7);
        Observer.Observe('million', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.GoToKey(8);
        Observer.Observe('hundred thousand', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.GoToKey(2);
        Observer.Observe('zero', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value) + '|' + Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Card.Close();
        Observer.Expect('ten', '10.00|10.00|10.00|10.00');
        Observer.Expect('ten and a half', '10.50|10.50|10.50|10.50');
        Observer.Expect('half', '0.50|0.50|0.50|0.50');
        Observer.Expect('negative', '-5.50|-5.50|-5.50|-5.50');
        Observer.Expect('million', '1,234,567.89|1,234,567.89|1,234,567.89|1,234,567.89');
        Observer.Expect('hundred thousand', '100,000.00|100,000.00|100,000.00|100,000.00');
        Observer.Expect('zero', '0.00|0.00|0.00|0.00');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Card_OtherFormatForms()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P135 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey(1);
        Observer.Observe('dec format 9', Format(Card.DecCtl, 0, 9));
        Observer.Observe('dec format 1', Format(Card.DecCtl, 0, 1));
        Observer.Observe('dec format 2', Format(Card.DecCtl, 0, 2));
        Observer.Observe('dec length 4', '[' + Format(Card.DecCtl, 4) + ']');
        Observer.Observe('dec length 12', '[' + Format(Card.DecCtl, 12) + ']');
        Observer.Observe('dec strsubstno', StrSubstNo('%1', Card.DecCtl));
        Observer.Observe('dec concatenation', 'x' + Format(Card.DecCtl) + 'y');
        Observer.Observe('dec custom', Format(Card.DecCtl, 0, '<Integer>'));
        Observer.Observe('int format 9', Format(Card.IntCtl, 0, 9));
        Observer.Observe('int strsubstno', StrSubstNo('%1', Card.IntCtl));
        Observer.Observe('int length 5', '[' + Format(Card.IntCtl, 5) + ']');
        Observer.Observe('bool format 9', Format(Card.BoolCtl, 0, 9));
        Observer.Observe('bool format 1', Format(Card.BoolCtl, 0, 1));
        Observer.Observe('date format 9', Format(Card.DtCtl, 0, 9));
        Observer.Observe('date format 1', Format(Card.DtCtl, 0, 1));
        Observer.Observe('date custom', Format(Card.DtCtl, 0, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('time format 9', Format(Card.TmCtl, 0, 9));
        Observer.Observe('datetime format 9', Format(Card.DtmCtl, 0, 9));
        Observer.Observe('duration format 9', Format(Card.DurCtl, 0, 9));
        Observer.Observe('option format 9', Format(Card.OptCtl, 0, 9));
        Observer.Observe('option format 2', Format(Card.OptCtl, 0, 2));
        Observer.Observe('enum format 9', Format(Card.EnCtl, 0, 9));
        Observer.Observe('enum format 2', Format(Card.EnCtl, 0, 2));
        Card.Close();
        Observer.Expect('dec format 9', '1,234.50');
        Observer.Expect('dec format 1', '1,234.50');
        Observer.Expect('dec format 2', '1,234.50');
        Observer.Expect('dec length 4', '[1,23]');
        Observer.Expect('dec length 12', '[1,234.50    ]');
        Observer.Expect('dec strsubstno', '1,234.50');
        Observer.Expect('dec concatenation', 'x1,234.50y');
        Observer.Expect('dec custom', '');
        Observer.Expect('int format 9', '1234567');
        Observer.Expect('int strsubstno', '1234567');
        Observer.Expect('int length 5', '[12345]');
        Observer.Expect('bool format 9', 'Yes');
        Observer.Expect('bool format 1', 'Yes');
        Observer.Expect('date format 9', '3/2/2024');
        Observer.Expect('date format 1', '3/2/2024');
        Observer.Expect('date custom', '');
        Observer.Expect('time format 9', '12:34:56 PM');
        Observer.Expect('datetime format 9', '3/2/2024 12:34 PM');
        Observer.Expect('duration format 9', '1 hour 2 minutes 3 seconds');
        Observer.Expect('option format 9', 'One');
        Observer.Expect('option format 2', 'One');
        Observer.Expect('enum format 9', 'Second Cap');
        Observer.Expect('enum format 2', 'Second Cap');
        Observer.Verify();
    end;

    [Test]
    procedure P135_List_FilledAndBlankRows()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P135 Fmt List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey(1);
        Observer.Observe('txtctl', Format(List.TxtCtl) + '|' + Format(List.TxtCtl.Value));
        Observer.Observe('cdctl', Format(List.CdCtl) + '|' + Format(List.CdCtl.Value));
        Observer.Observe('intctl', Format(List.IntCtl) + '|' + Format(List.IntCtl.Value));
        Observer.Observe('bigctl', Format(List.BigCtl) + '|' + Format(List.BigCtl.Value));
        Observer.Observe('decctl', Format(List.DecCtl) + '|' + Format(List.DecCtl.Value));
        Observer.Observe('decplacesctl', Format(List.DecPlacesCtl) + '|' + Format(List.DecPlacesCtl.Value));
        Observer.Observe('boolctl', Format(List.BoolCtl) + '|' + Format(List.BoolCtl.Value));
        Observer.Observe('dtctl', Format(List.DtCtl) + '|' + Format(List.DtCtl.Value));
        Observer.Observe('tmctl', Format(List.TmCtl) + '|' + Format(List.TmCtl.Value));
        Observer.Observe('dtmctl', Format(List.DtmCtl) + '|' + Format(List.DtmCtl.Value));
        Observer.Observe('durctl', Format(List.DurCtl) + '|' + Format(List.DurCtl.Value));
        Observer.Observe('optctl', Format(List.OptCtl) + '|' + Format(List.OptCtl.Value));
        Observer.Observe('enctl', Format(List.EnCtl) + '|' + Format(List.EnCtl.Value));
        Observer.Observe('blankintctl', Format(List.BlankIntCtl) + '|' + Format(List.BlankIntCtl.Value));
        List.GoToKey(3);
        Observer.Observe('row 3 dec', Format(List.DecCtl) + '|' + Format(List.DecCtl.Value));
        List.GoToKey(2);
        Observer.Observe('row 2 dec', Format(List.DecCtl) + '|' + Format(List.DecCtl.Value));
        List.Close();
        Observer.Expect('txtctl', 'Hello|Hello');
        Observer.Expect('cdctl', 'ABC|ABC');
        Observer.Expect('intctl', '1234567|1234567');
        Observer.Expect('bigctl', '4294967294|4294967294');
        Observer.Expect('decctl', '1,234.50|1,234.50');
        Observer.Expect('decplacesctl', '1,234.50|1,234.50');
        Observer.Expect('boolctl', 'Yes|Yes');
        Observer.Expect('dtctl', '3/2/2024|3/2/2024');
        Observer.Expect('tmctl', '12:34:56 PM|12:34:56 PM');
        Observer.Expect('dtmctl', '3/2/2024 12:34 PM|3/2/2024 12:34 PM');
        Observer.Expect('durctl', '1 hour 2 minutes 3 seconds|1 hour 2 minutes 3 seconds');
        Observer.Expect('optctl', 'One|One');
        Observer.Expect('enctl', 'Second Cap|Second Cap');
        Observer.Expect('blankintctl', '1234567|1234567');
        Observer.Expect('row 3 dec', '10.00|10.00');
        Observer.Expect('row 2 dec', '0.00|0.00');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Card_FormatAfterSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P135 Fmt Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey(3);
        Card.DecCtl.SetValue(12.5);
        Observer.Observe('dec after set 12.5', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value));
        Card.DecCtl.SetValue(7);
        Observer.Observe('dec after set 7', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value));
        Card.IntCtl.SetValue(42);
        Observer.Observe('int after set', Format(Card.IntCtl) + '|' + Format(Card.IntCtl.Value));
        Card.DtCtl.SetValue(20250101D);
        Observer.Observe('date after set', Format(Card.DtCtl) + '|' + Format(Card.DtCtl.Value));
        Card.BoolCtl.SetValue(true);
        Observer.Observe('bool after set', Format(Card.BoolCtl) + '|' + Format(Card.BoolCtl.Value));
        Card.TxtCtl.SetValue('abc');
        Observer.Observe('text after set', Format(Card.TxtCtl) + '|' + Format(Card.TxtCtl.Value));
        Card.Close();
        Observer.Expect('dec after set 12.5', '12.50|12.50');
        Observer.Expect('dec after set 7', '7.00|7.00');
        Observer.Expect('int after set', '42|42');
        Observer.Expect('date after set', '1/1/2025|1/1/2025');
        Observer.Expect('bool after set', 'Yes|Yes');
        Observer.Expect('text after set', 'abc|abc');
        Observer.Verify();
    end;
}
