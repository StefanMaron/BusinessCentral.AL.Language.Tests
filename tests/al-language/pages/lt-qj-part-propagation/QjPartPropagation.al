// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-updatepropagation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QJ *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: (1) a Document card over table H with a ListPart over table L (SubPageLink), the part control with UpdatePropagation = Both,
//   SubPart and not set. A part field's OnValidate modifies the H row (Get + Modify, another field) and calls CurrPage.Update(false); then a
//   host action runs Rec.Validate of a third H field and CurrPage.SaveRecord(). Observed: the host and part triggers with their Rec/xRec
//   values, the host controls, the stored H row after each step, and whether 'changed by another user' is raised. Also with an unsaved
//   host edit typed before the part edit.
//   (2) a subform field's OnValidate that calls CurrPage.SaveRecord() and reads Rec and xRec of the same field before and after the call,
//   for a new typed row and for an edited stored row, each edited twice (Microsoft's DeltaUpdateTotals adds Rec minus xRec).
// Settles al-runtime-rs docs/probes-needed.md assumption part-update-propagation-both-refreshes-host (Tests-ERM 134344 and about 160 more).
// BC versions: 29 (27 and 28 by CI)

table 86880 "LT QJ Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Total; Decimal) { }
        field(3; Descr; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT QJ Log";
            begin
                Log.Add('T.H.Descr.V(' + Descr + ' x=' + xRec.Descr + ' t=' + Format(Total) + ' x.t=' + Format(xRec.Total) + ')');
            end;
        }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT QJ Log";
    begin
        Log.Add('T.H.MOD(t=' + Format(Total) + ' d=' + Descr + ' n=' + Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

table 86881 "LT QJ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Decimal) { }
        field(4; Amt; Decimal) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

codeunit 86882 "LT QJ Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Take(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' ';
            Result += Line;
        end;
        Clear(Lines);
        exit(Result);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;
}

page 86883 "LT QJ Lines"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(QtyF; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Head: Record "LT QJ Head";
                    begin
                        Log.Add('L.Qty.V(' + Format(Rec.Qty) + ' x=' + Format(xRec.Qty) + ')');
                        Head.Get(Rec."Doc No.");
                        Head.Total := Head.Total + Rec.Qty - xRec.Qty;
                        Head.Modify();
                        CurrPage.Update(false);
                        Log.Add('L.Qty.V.end');
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('L.AGR(' + Format(Rec."Line No.") + ' q=' + Format(Rec.Qty) + ' x.q=' + Format(xRec.Qty) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('L.AGCR(' + Format(Rec."Line No.") + ' q=' + Format(Rec.Qty) + ' x.q=' + Format(xRec.Qty) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('L.MODR(' + Format(Rec."Line No.") + ' q=' + Format(Rec.Qty) + ' x.q=' + Format(xRec.Qty) + ')');
    end;
}

page 86884 "LT QJ Host Both"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('H.ACT(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                    Rec.Validate(Descr, 'by action');
                    CurrPage.SaveRecord();
                    Log.Add('H.ACT.end(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

page 86885 "LT QJ Host SubPart"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = SubPart;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('H.ACT(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                    Rec.Validate(Descr, 'by action');
                    CurrPage.SaveRecord();
                    Log.Add('H.ACT.end(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

page 86886 "LT QJ Host Default"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(TotalF; Rec.Total) { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateSave)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('H.ACT(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                    Rec.Validate(Descr, 'by action');
                    CurrPage.SaveRecord();
                    Log.Add('H.ACT.end(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' d=' + Rec.Descr + ' n=' + Rec.Note + ' x.t=' + Format(xRec.Total) + ' x.d=' + xRec.Descr + ')');
    end;
}

page 86887 "LT QJ Save Lines"
{
    PageType = ListPart;
    SourceTable = "LT QJ Line";
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(AmtF; Rec.Amt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('S.V.before(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
                        CurrPage.SaveRecord();
                        Log.Add('S.V.after(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ' delta=' + Format(Rec.Amt - xRec.Amt) + ')');
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('S.AGCR(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('S.NEW(x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('S.INSR(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ' x.ln=' + Format(xRec."Line No.") + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('S.MODR(' + Format(Rec."Line No.") + ' r=' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ')');
    end;
}

page 86888 "LT QJ Save Host"
{
    PageType = Document;
    SourceTable = "LT QJ Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
            part(Lines; "LT QJ Save Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

codeunit 86889 "LT QJ Part Propagation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QJ Log";

    local procedure Seed()
    var
        Head: Record "LT QJ Head";
        Line: Record "LT QJ Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'H1';
        Head.Total := 1;
        Head.Descr := 'orig';
        Head.Note := 'orig';
        Head.Insert();
        Line."Doc No." := 'H1';
        Line."Line No." := 10000;
        Line.Qty := 1;
        Line.Amt := 1;
        Line.Insert();
        Log.Reset();
    end;

    local procedure Stored(): Text
    var
        Head: Record "LT QJ Head";
    begin
        if not Head.Get('H1') then
            exit('<no header>');
        exit('t=' + Format(Head.Total) + ' d=' + Head.Descr + ' n=' + Head.Note);
    end;

    local procedure StoredLines(): Text
    var
        Line: Record "LT QJ Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", 'H1');
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Format(Line."Line No.") + ':q=' + Format(Line.Qty) + ',a=' + Format(Line.Amt);
            until Line.Next() = 0;
        exit(Result);
    end;

    // ---- (1) part OnValidate modifies the host row, then the host action validates and saves ----

    [Test]
    procedure QJ_Both_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('host-descr-after-action', TP.DescrF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QJ_SubPart_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('host-descr-after-action', TP.DescrF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QJ_Default_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('host-descr-after-action', TP.DescrF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    // The host holds an unsaved edit (Note typed) when the part edit modifies the host row.

    [Test]
    procedure QJ_Both_HostEdited_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.NoteF.SetValue('typed');
        Observer.Observe('log-open-and-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('host-note-after-part', TP.NoteF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure QJ_SubPart_HostEdited_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.NoteF.SetValue('typed');
        Observer.Observe('log-open-and-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('host-note-after-part', TP.NoteF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure QJ_Default_HostEdited_PartModifiesHost_ThenHostSave()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.NoteF.SetValue('typed');
        Observer.Observe('log-open-and-host-edit', Log.Take());
        Observer.Observe('stored-after-host-edit', Stored());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('host-note-after-part', TP.NoteF.Value());
        Observer.Observe('stored-after-part', Stored());
        TP.ValidateSave.Invoke();
        Observer.Observe('log-action', Log.Take());
        Observer.Observe('host-total-after-action', TP.TotalF.Value());
        Observer.Observe('stored-after-action', Stored());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Finish();
    end;

    // ---- (2) subform OnValidate: CurrPage.SaveRecord() and Rec/xRec of the same field before and after ----

    [Test]
    procedure QJ_SubformSaveRecord_StoredRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-first-edit', Log.Take());
        Observer.Observe('lines-after-first-edit', StoredLines());
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-second-edit', Log.Take());
        Observer.Observe('lines-after-second-edit', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QJ_SubformSaveRecord_NewRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-open-and-new', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-first-edit', Log.Take());
        Observer.Observe('lines-after-first-edit', StoredLines());
        TP.Lines.AmtF.SetValue(7);
        Observer.Observe('log-second-edit', Log.Take());
        Observer.Observe('lines-after-second-edit', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;
}
