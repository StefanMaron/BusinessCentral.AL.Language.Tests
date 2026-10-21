// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QI EE *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Error('') (an error with an empty text) raised from a TestPage action's Invoke, from a control OnValidate (SetValue) and from an
//   OnOpenPage (OpenEdit), with and without asserterror, next to Error('text') and a [TryFunction] that raises Error(''): whether the
//   test method goes on, GetLastErrorText / GetLastErrorCode, and whether the rows the trigger wrote before the error stay.
// Settles al-runtime-rs docs/probes-needed.md row "An error with an empty text (Error('')) out of a TestPage action's Invoke"
//   (Gen. Jnl.-Post Preview ends every posting preview with Error(''); Tests-ERM 134760, 134762, 134227).
// BC versions: 29 (27 and 28 by CI)

table 86850 "LT QI EE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 86851 "LT QI EE Card"
{
    PageType = Card;
    SourceTable = "LT QI EE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Mark(300, 'validate ' + Rec.Name);
                        if Rec.Name = 'empty' then
                            Error('');
                        if Rec.Name = 'text' then
                            Error('LT QI validate error');
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EmptyAct)
            {
                ApplicationArea = All;
                Caption = 'Empty error';

                trigger OnAction()
                begin
                    Mark(100, 'empty action ran');
                    Error('');
                end;
            }
            action(TextAct)
            {
                ApplicationArea = All;
                Caption = 'Text error';

                trigger OnAction()
                begin
                    Mark(101, 'text action ran');
                    Error('LT QI action error');
                end;
            }
            action(TryEmptyAct)
            {
                ApplicationArea = All;
                Caption = 'Try empty error';

                trigger OnAction()
                var
                    Ok: Boolean;
                begin
                    Ok := TryEmpty();
                    Mark(102, 'try=' + Format(Ok) + ' text=[' + GetLastErrorText() + '] code=[' + GetLastErrorCode() + ']');
                end;
            }
        }
    }

    [TryFunction]
    local procedure TryEmpty()
    begin
        Error('');
    end;

    local procedure Mark(MarkId: Integer; MarkName: Text)
    var
        Row: Record "LT QI EE Row";
    begin
        Row.Init();
        Row.Id := MarkId;
        Row.Name := CopyStr(MarkName, 1, MaxStrLen(Row.Name));
        if not Row.Insert() then
            Row.Modify();
    end;
}

page 86852 "LT QI EE Open Card"
{
    PageType = Card;
    SourceTable = "LT QI EE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Row: Record "LT QI EE Row";
    begin
        Row.Init();
        Row.Id := 200;
        Row.Name := 'open ran';
        Row.Insert();
        Error('');
    end;
}

codeunit 86853 "LT QI EE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT QI EE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'seed';
        Row.Insert();
        ClearLastError();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT QI EE Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '=' + Row.Name + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    // ---- action Invoke ----

    [Test]
    procedure QI_EE_EmptyAction_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.EmptyAct.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure QI_EE_EmptyAction_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.EmptyAct.Invoke();
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-invoke');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure QI_EE_TextAction_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.TextAct.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure QI_EE_TryEmptyAction()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.TryEmptyAct.Invoke();
        Observer.ObserveError('after-invoke');
        Observer.Observe('rows', Rows());
        Card.Close();
        Observer.Finish();
    end;

    // ---- control OnValidate (SetValue) ----

    [Test]
    procedure QI_EE_EmptyValidate_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.NameCtl.SetValue('empty');
        Observer.ObserveError('setvalue');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Observe('rows-after-close', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure QI_EE_EmptyValidate_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.NameCtl.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Observe('rows-after-close', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure QI_EE_TextValidate_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.NameCtl.SetValue('text');
        Observer.ObserveError('setvalue');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Observe('rows-after-close', Rows());
        Observer.Finish();
    end;

    // ---- OnOpenPage (OpenEdit) ----

    [Test]
    procedure QI_EE_EmptyOpen_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Open Card";
    begin
        Seed();
        asserterror Card.OpenEdit();
        Observer.ObserveError('open');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure QI_EE_EmptyOpen_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Open Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-open');
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;
}
