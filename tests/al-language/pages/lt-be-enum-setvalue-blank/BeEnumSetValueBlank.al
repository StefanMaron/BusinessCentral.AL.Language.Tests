// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enums 81150-81152, table 81150, page 81150, codeunit 81150, test codeunit 81160
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: TestPage field SetValue on an Enum control whose value 0 is " " with Caption = ' ' (a space), as on page 113 "Budget"
//   (control GLAccCategory shows a page variable of Enum "G/L Account Category"; Microsoft's ERM Budget tests 134922/134927 call SetValue(0)).
//   Controls: a table field and a page variable, each for an enum with AssignmentCompatibility = true (like enum 15), an enum without it, an enum
//   whose value 0 has a normal caption ('Zero'), and an Option with OptionCaption ' ,Alpha,Beta' for comparison.
//   Inputs: Integer 0, 1, 2, 5; Text ' ', '', '1', 'Alpha'; the value-0 member itself. Each input runs on a freshly opened page (start = value 0)
//   and after SetValue('Beta') (start = value 2). Per input: whether SetValue raised and its error text/code, the control's Value afterwards,
//   the ordinals the control's OnValidate saw (log), and for a field control the stored ordinal after Close.
// Corpus issue: StefanMaron/BusinessCentral.AL.Language.Tests#660 item 1.
// BC versions: all (CI)

enum 81150 "LT BE Blank Enum Compat"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

enum 81151 "LT BE Blank Enum Strict"
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

enum 81152 "LT BE Plain Enum"
{
    Extensible = false;

    value(0; Zero) { Caption = 'Zero'; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

table 81150 "LT BE Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ECompat; Enum "LT BE Blank Enum Compat") { }
        field(3; EStrict; Enum "LT BE Blank Enum Strict") { }
        field(4; EPlain; Enum "LT BE Plain Enum") { }
        field(5; Opt; Option) { OptionMembers = " ",Alpha,Beta; OptionCaption = ' ,Alpha,Beta'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 81150 "LT BE Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 81150 "LT BE Enum Card"
{
    PageType = Card;
    SourceTable = "LT BE Enum Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(FCompat; Rec.ECompat)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add(Format(Rec.ECompat.AsInteger()));
                end;
            }
            field(FStrict; Rec.EStrict)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add(Format(Rec.EStrict.AsInteger()));
                end;
            }
            field(FPlain; Rec.EPlain)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add(Format(Rec.EPlain.AsInteger()));
                end;
            }
            field(FOpt; Rec.Opt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    N: Integer;
                begin
                    N := Rec.Opt;
                    Log.Add(Format(N));
                end;
            }
            field(VCompat; VarCompat)
            {
                ApplicationArea = All;
                Caption = 'Compat Filter';
                trigger OnValidate()
                begin
                    Log.Add(Format(VarCompat.AsInteger()));
                end;
            }
            field(VStrict; VarStrict)
            {
                ApplicationArea = All;
                Caption = 'Strict Filter';
                trigger OnValidate()
                begin
                    Log.Add(Format(VarStrict.AsInteger()));
                end;
            }
            field(VPlain; VarPlain)
            {
                ApplicationArea = All;
                Caption = 'Plain Filter';
                trigger OnValidate()
                begin
                    Log.Add(Format(VarPlain.AsInteger()));
                end;
            }
            field(VOpt; VarOpt)
            {
                ApplicationArea = All;
                Caption = 'Option Filter';
                OptionCaption = ' ,Alpha,Beta';
                trigger OnValidate()
                var
                    N: Integer;
                begin
                    N := VarOpt;
                    Log.Add(Format(N));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Log";
        VarCompat: Enum "LT BE Blank Enum Compat";
        VarStrict: Enum "LT BE Blank Enum Strict";
        VarPlain: Enum "LT BE Plain Enum";
        VarOpt: Option " ",Alpha,Beta;
}

codeunit 81160 "LT BE Enum SetValue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT BE Log";

    local procedure Seed()
    var
        Row: Record "LT BE Enum Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
    end;

    local procedure StoredOrdinal(Ctl: Text): Text
    var
        Row: Record "LT BE Enum Row";
        N: Integer;
    begin
        Row.Get(1);
        case Ctl of
            'FCompat':
                exit(Format(Row.ECompat.AsInteger()));
            'FStrict':
                exit(Format(Row.EStrict.AsInteger()));
            'FPlain':
                exit(Format(Row.EPlain.AsInteger()));
            'FOpt':
                begin
                    N := Row.Opt;
                    exit(Format(N));
                end;
        end;
        exit('n/a');
    end;

    [TryFunction]
    local procedure TrySet(var TP: TestPage "LT BE Enum Card"; Ctl: Text; Input: Variant)
    begin
        case Ctl of
            'FCompat':
                TP.FCompat.SetValue(Input);
            'FStrict':
                TP.FStrict.SetValue(Input);
            'FPlain':
                TP.FPlain.SetValue(Input);
            'FOpt':
                TP.FOpt.SetValue(Input);
            'VCompat':
                TP.VCompat.SetValue(Input);
            'VStrict':
                TP.VStrict.SetValue(Input);
            'VPlain':
                TP.VPlain.SetValue(Input);
            'VOpt':
                TP.VOpt.SetValue(Input);
        end;
    end;

    local procedure ValueOf(var TP: TestPage "LT BE Enum Card"; Ctl: Text): Text
    begin
        case Ctl of
            'FCompat':
                exit(TP.FCompat.Value());
            'FStrict':
                exit(TP.FStrict.Value());
            'FPlain':
                exit(TP.FPlain.Value());
            'FOpt':
                exit(TP.FOpt.Value());
            'VCompat':
                exit(TP.VCompat.Value());
            'VStrict':
                exit(TP.VStrict.Value());
            'VPlain':
                exit(TP.VPlain.Value());
            'VOpt':
                exit(TP.VOpt.Value());
        end;
    end;

    [TryFunction]
    local procedure TryClose(var TP: TestPage "LT BE Enum Card")
    begin
        TP.Close();
    end;

    // One input on a freshly opened page; FromBeta first sets the control to 'Beta' (text, by caption).
    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Ctl: Text; FromBeta: Boolean; Tag: Text; Input: Variant)
    var
        TP: TestPage "LT BE Enum Card";
        Ok: Boolean;
    begin
        Seed();
        TP.OpenEdit();
        if FromBeta then begin
            TP.First();
            if not TrySet(TP, Ctl, 'Beta') then
                Observer.ObserveError(Tag + '-startBeta');
            Log.Take();
        end;
        Ok := TrySet(TP, Ctl, Input);
        Observer.Observe(Tag, Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + '-err');
        Observer.Observe(Tag + '-value', '[' + ValueOf(TP, Ctl) + ']');
        Observer.Observe(Tag + '-log', '[' + Log.Take() + ']');
        if not TryClose(TP) then
            Observer.ObserveError(Tag + '-close');
        if CopyStr(Ctl, 1, 1) = 'F' then
            Observer.Observe(Tag + '-stored', StoredOrdinal(Ctl));
    end;

    [Test]
    procedure SetValue_FCompat_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'int0', 0);
        RunCase(Observer, 'FCompat', false, 'int1', 1);
        RunCase(Observer, 'FCompat', false, 'int2', 2);
        RunCase(Observer, 'FCompat', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FCompat_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'space', ' ');
        RunCase(Observer, 'FCompat', false, 'empty', '');
        RunCase(Observer, 'FCompat', false, 'digit1', '1');
        RunCase(Observer, 'FCompat', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FCompat', false, 'member0', "LT BE Blank Enum Compat"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FCompat_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'int0', 0);
        RunCase(Observer, 'FCompat', true, 'int1', 1);
        RunCase(Observer, 'FCompat', true, 'int2', 2);
        RunCase(Observer, 'FCompat', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FCompat_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'space', ' ');
        RunCase(Observer, 'FCompat', true, 'empty', '');
        RunCase(Observer, 'FCompat', true, 'digit1', '1');
        RunCase(Observer, 'FCompat', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FCompat', true, 'member0', "LT BE Blank Enum Compat"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FStrict_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'int0', 0);
        RunCase(Observer, 'FStrict', false, 'int1', 1);
        RunCase(Observer, 'FStrict', false, 'int2', 2);
        RunCase(Observer, 'FStrict', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FStrict_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'space', ' ');
        RunCase(Observer, 'FStrict', false, 'empty', '');
        RunCase(Observer, 'FStrict', false, 'digit1', '1');
        RunCase(Observer, 'FStrict', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FStrict', false, 'member0', "LT BE Blank Enum Strict"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FStrict_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'int0', 0);
        RunCase(Observer, 'FStrict', true, 'int1', 1);
        RunCase(Observer, 'FStrict', true, 'int2', 2);
        RunCase(Observer, 'FStrict', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FStrict_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'space', ' ');
        RunCase(Observer, 'FStrict', true, 'empty', '');
        RunCase(Observer, 'FStrict', true, 'digit1', '1');
        RunCase(Observer, 'FStrict', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FStrict', true, 'member0', "LT BE Blank Enum Strict"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FPlain_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'int0', 0);
        RunCase(Observer, 'FPlain', false, 'int1', 1);
        RunCase(Observer, 'FPlain', false, 'int2', 2);
        RunCase(Observer, 'FPlain', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FPlain_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'space', ' ');
        RunCase(Observer, 'FPlain', false, 'empty', '');
        RunCase(Observer, 'FPlain', false, 'digit1', '1');
        RunCase(Observer, 'FPlain', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FPlain', false, 'member0', "LT BE Plain Enum"::Zero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FPlain_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'int0', 0);
        RunCase(Observer, 'FPlain', true, 'int1', 1);
        RunCase(Observer, 'FPlain', true, 'int2', 2);
        RunCase(Observer, 'FPlain', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FPlain_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'space', ' ');
        RunCase(Observer, 'FPlain', true, 'empty', '');
        RunCase(Observer, 'FPlain', true, 'digit1', '1');
        RunCase(Observer, 'FPlain', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FPlain', true, 'member0', "LT BE Plain Enum"::Zero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FOpt_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'int0', 0);
        RunCase(Observer, 'FOpt', false, 'int1', 1);
        RunCase(Observer, 'FOpt', false, 'int2', 2);
        RunCase(Observer, 'FOpt', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FOpt_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'space', ' ');
        RunCase(Observer, 'FOpt', false, 'empty', '');
        RunCase(Observer, 'FOpt', false, 'digit1', '1');
        RunCase(Observer, 'FOpt', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FOpt', false, 'member0', OptZero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FOpt_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'int0', 0);
        RunCase(Observer, 'FOpt', true, 'int1', 1);
        RunCase(Observer, 'FOpt', true, 'int2', 2);
        RunCase(Observer, 'FOpt', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FOpt_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'space', ' ');
        RunCase(Observer, 'FOpt', true, 'empty', '');
        RunCase(Observer, 'FOpt', true, 'digit1', '1');
        RunCase(Observer, 'FOpt', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'FOpt', true, 'member0', OptZero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VCompat_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'int0', 0);
        RunCase(Observer, 'VCompat', false, 'int1', 1);
        RunCase(Observer, 'VCompat', false, 'int2', 2);
        RunCase(Observer, 'VCompat', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VCompat_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'space', ' ');
        RunCase(Observer, 'VCompat', false, 'empty', '');
        RunCase(Observer, 'VCompat', false, 'digit1', '1');
        RunCase(Observer, 'VCompat', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VCompat', false, 'member0', "LT BE Blank Enum Compat"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VCompat_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'int0', 0);
        RunCase(Observer, 'VCompat', true, 'int1', 1);
        RunCase(Observer, 'VCompat', true, 'int2', 2);
        RunCase(Observer, 'VCompat', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VCompat_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'space', ' ');
        RunCase(Observer, 'VCompat', true, 'empty', '');
        RunCase(Observer, 'VCompat', true, 'digit1', '1');
        RunCase(Observer, 'VCompat', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VCompat', true, 'member0', "LT BE Blank Enum Compat"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VStrict_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'int0', 0);
        RunCase(Observer, 'VStrict', false, 'int1', 1);
        RunCase(Observer, 'VStrict', false, 'int2', 2);
        RunCase(Observer, 'VStrict', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VStrict_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'space', ' ');
        RunCase(Observer, 'VStrict', false, 'empty', '');
        RunCase(Observer, 'VStrict', false, 'digit1', '1');
        RunCase(Observer, 'VStrict', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VStrict', false, 'member0', "LT BE Blank Enum Strict"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VStrict_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'int0', 0);
        RunCase(Observer, 'VStrict', true, 'int1', 1);
        RunCase(Observer, 'VStrict', true, 'int2', 2);
        RunCase(Observer, 'VStrict', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VStrict_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'space', ' ');
        RunCase(Observer, 'VStrict', true, 'empty', '');
        RunCase(Observer, 'VStrict', true, 'digit1', '1');
        RunCase(Observer, 'VStrict', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VStrict', true, 'member0', "LT BE Blank Enum Strict"::" ");
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VPlain_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'int0', 0);
        RunCase(Observer, 'VPlain', false, 'int1', 1);
        RunCase(Observer, 'VPlain', false, 'int2', 2);
        RunCase(Observer, 'VPlain', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VPlain_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'space', ' ');
        RunCase(Observer, 'VPlain', false, 'empty', '');
        RunCase(Observer, 'VPlain', false, 'digit1', '1');
        RunCase(Observer, 'VPlain', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VPlain', false, 'member0', "LT BE Plain Enum"::Zero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VPlain_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'int0', 0);
        RunCase(Observer, 'VPlain', true, 'int1', 1);
        RunCase(Observer, 'VPlain', true, 'int2', 2);
        RunCase(Observer, 'VPlain', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VPlain_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'space', ' ');
        RunCase(Observer, 'VPlain', true, 'empty', '');
        RunCase(Observer, 'VPlain', true, 'digit1', '1');
        RunCase(Observer, 'VPlain', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VPlain', true, 'member0', "LT BE Plain Enum"::Zero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VOpt_Integers_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'int0', 0);
        RunCase(Observer, 'VOpt', false, 'int1', 1);
        RunCase(Observer, 'VOpt', false, 'int2', 2);
        RunCase(Observer, 'VOpt', false, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VOpt_Texts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'space', ' ');
        RunCase(Observer, 'VOpt', false, 'empty', '');
        RunCase(Observer, 'VOpt', false, 'digit1', '1');
        RunCase(Observer, 'VOpt', false, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VOpt', false, 'member0', OptZero);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VOpt_Integers_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'int0', 0);
        RunCase(Observer, 'VOpt', true, 'int1', 1);
        RunCase(Observer, 'VOpt', true, 'int2', 2);
        RunCase(Observer, 'VOpt', true, 'int5', 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_VOpt_Texts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'space', ' ');
        RunCase(Observer, 'VOpt', true, 'empty', '');
        RunCase(Observer, 'VOpt', true, 'digit1', '1');
        RunCase(Observer, 'VOpt', true, 'capAlpha', 'Alpha');
        RunCase(Observer, 'VOpt', true, 'member0', OptZero);
        Observer.Finish();
    end;
}
