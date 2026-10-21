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
// Results (BC 29.0): with Both, SubPart and not set alike the host re-reads its row after the part's Update(false) (H.AGR/H.AGCR with the
//   part's Total; with Both the host's triggers run before the part's re-read, otherwise after it), no 'changed by another user' is raised,
//   the host's later save keeps the part's change, and the part's own typed Qty is not saved (Update(false) re-reads the line). An unsaved
//   host edit is saved (H.MODR) before the part's OnValidate runs. In a subform OnValidate, CurrPage.SaveRecord() changes neither Rec nor
//   xRec; for a new row Rec gets the AutoSplitKey line number and xRec stays the blank new row.
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

// ---- Writer QL additions (2026-10-21): a part edit that does not change the host row, a new part row, GoToKey and New counts ----

page 86970 "LT QL Note Lines"
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
                        Log.Add('N.Amt.V(' + Format(Rec.Amt) + ' x=' + Format(xRec.Amt) + ')');
                        CurrPage.Update(false);
                        Log.Add('N.Amt.V.end');
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('N.AGR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x.a=' + Format(xRec.Amt) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('N.AGCR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x.a=' + Format(xRec.Amt) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('N.MODR(' + Format(Rec."Line No.") + ' a=' + Format(Rec.Amt) + ' x.a=' + Format(xRec.Amt) + ')');
    end;
}

page 86971 "LT QL Note Host Both"
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
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 86972 "LT QL Note Host SubPart"
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
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = SubPart;
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
}

page 86973 "LT QL Note Host Default"
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
            }
            part(Lines; "LT QL Note Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    var
        Log: Codeunit "LT QJ Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MODR(t=' + Format(Rec.Total) + ' x.t=' + Format(xRec.Total) + ')');
    end;
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
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=1) L.Qty.V.end H.AGR(t=5 d=orig n=orig x.t=1) H.AGCR(t=5 d=orig n=orig x.t=1) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=5 d=orig n=orig');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=orig x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=orig x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=orig x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=orig x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('host-descr-after-action', 'by action');
        Observer.Expect('stored-after-action', 't=5 d=by action n=orig');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
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
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=orig x.t=1) H.AGCR(t=5 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=5 d=orig n=orig');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=orig x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=orig x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=orig x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=orig x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('host-descr-after-action', 'by action');
        Observer.Expect('stored-after-action', 't=5 d=by action n=orig');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
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
        Observer.Expect('log-open', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('log-part-edit', 'L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=orig x.t=1) H.AGCR(t=5 d=orig n=orig x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('stored-after-part', 't=5 d=orig n=orig');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=orig x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=orig x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=orig x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=orig x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('host-descr-after-action', 'by action');
        Observer.Expect('stored-after-action', 't=5 d=by action n=orig');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=orig');
        Observer.Expect('lines-after-close', '10000:q=1,a=1');
        Observer.Verify();
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
        Observer.Expect('log-open-and-host-edit', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=1 d=orig n=typed x.t=1 x.d=orig) T.H.MOD(t=1 d=orig n=typed x.t=1 x.d=orig) L.Qty.V(5 x=1) L.Qty.V.end H.AGR(t=5 d=orig n=typed x.t=1) H.AGCR(t=5 d=orig n=typed x.t=1) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('host-note-after-part', 'typed');
        Observer.Expect('stored-after-part', 't=5 d=orig n=typed');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=typed x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=typed x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=typed x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=typed x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('stored-after-action', 't=5 d=by action n=typed');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=typed');
        Observer.Verify();
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
        Observer.Expect('log-open-and-host-edit', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=1 d=orig n=typed x.t=1 x.d=orig) T.H.MOD(t=1 d=orig n=typed x.t=1 x.d=orig) L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=typed x.t=1) H.AGCR(t=5 d=orig n=typed x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('host-note-after-part', 'typed');
        Observer.Expect('stored-after-part', 't=5 d=orig n=typed');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=typed x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=typed x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=typed x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=typed x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('stored-after-action', 't=5 d=by action n=typed');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=typed');
        Observer.Verify();
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
        Observer.Expect('log-open-and-host-edit', 'H.AGR(t=1 d=orig n=orig x.t=0) H.AGCR(t=1 d=orig n=orig x.t=0) L.AGR(10000 q=1 x.q=0) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=0) H.AGR(t=1 d=orig n=orig x.t=1) H.AGCR(t=1 d=orig n=orig x.t=1)');
        Observer.Expect('stored-after-host-edit', 't=1 d=orig n=orig');
        Observer.Expect('log-part-edit', 'H.MODR(t=1 d=orig n=typed x.t=1 x.d=orig) T.H.MOD(t=1 d=orig n=typed x.t=1 x.d=orig) L.Qty.V(5 x=1) L.Qty.V.end L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=5) H.AGR(t=5 d=orig n=typed x.t=1) H.AGCR(t=5 d=orig n=typed x.t=1)');
        Observer.Expect('host-total-after-part', '5.00');
        Observer.Expect('host-note-after-part', 'typed');
        Observer.Expect('stored-after-part', 't=5 d=orig n=typed');
        Observer.Expect('log-action', 'H.AGR(t=5 d=orig n=typed x.t=5) H.ACT(t=5 d=orig) T.H.Descr.V(by action x=orig t=5 x.t=5) H.MODR(t=5 d=by action n=typed x.t=5 x.d=orig) T.H.MOD(t=5 d=by action n=typed x.t=5 x.d=orig) H.ACT.end(t=5 d=by action) H.AGR(t=5 d=by action n=typed x.t=5) L.AGR(10000 q=1 x.q=1) L.AGR(10000 q=1 x.q=1) L.AGCR(10000 q=1 x.q=1)');
        Observer.Expect('host-total-after-action', '5.00');
        Observer.Expect('stored-after-action', 't=5 d=by action n=typed');
        Observer.Expect('log-close', '');
        Observer.Expect('stored-after-close', 't=5 d=by action n=typed');
        Observer.Verify();
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
        Observer.Expect('log-open', 'S.AGCR(10000 r=1 x=0)');
        Observer.Expect('log-first-edit', 'S.V.before(10000 r=5 x=1 x.ln=10000) S.MODR(10000 r=5 x=1) S.V.after(10000 r=5 x=1 x.ln=10000 delta=4)');
        Observer.Expect('lines-after-first-edit', '10000:q=1,a=5');
        Observer.Expect('log-second-edit', 'S.V.before(10000 r=7 x=5 x.ln=10000) S.MODR(10000 r=7 x=5) S.V.after(10000 r=7 x=5 x.ln=10000 delta=2)');
        Observer.Expect('lines-after-second-edit', '10000:q=1,a=7');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=7');
        Observer.Verify();
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
        Observer.Expect('log-open-and-new', 'S.AGCR(10000 r=1 x=0) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0) S.AGCR(10000 r=1 x=1) S.NEW(x=1 x.ln=10000) S.AGCR(0 r=0 x=0)');
        Observer.Expect('log-first-edit', 'S.V.before(0 r=5 x=0 x.ln=0) S.INSR(20000 r=5 x=0 x.ln=0) S.V.after(20000 r=5 x=0 x.ln=0 delta=5)');
        Observer.Expect('lines-after-first-edit', '10000:q=1,a=1 20000:q=0,a=5');
        Observer.Expect('log-second-edit', 'S.V.before(20000 r=7 x=5 x.ln=20000) S.MODR(20000 r=7 x=5) S.V.after(20000 r=7 x=5 x.ln=20000 delta=2)');
        Observer.Expect('lines-after-second-edit', '10000:q=1,a=1 20000:q=0,a=7');
        Observer.Expect('log-close', '');
        Observer.Expect('lines-after-close', '10000:q=1,a=1 20000:q=0,a=7');
        Observer.Verify();
    end;

    // ---- Writer QL (2026-10-21): (3) a new part row (DelayedInsert) whose OnValidate modifies the host row and calls CurrPage.Update(false);
    // a part edit whose code does not change the host row; (4) OpenEdit + GoToKey on a Document host and New on the part: trigger counts ----

    local procedure SeedQl()
    var
        Head: Record "LT QJ Head";
        Line: Record "LT QJ Line";
    begin
        Seed();
        Head."No." := 'H2';
        Head.Total := 2;
        Head.Descr := 'two';
        Head.Note := 'two';
        Head.Insert();
        Head."No." := 'H3';
        Head.Total := 3;
        Head.Descr := 'three';
        Head.Note := 'three';
        Head.Insert();
        Line."Doc No." := 'H2';
        Line."Line No." := 30000;
        Line.Qty := 3;
        Line.Amt := 3;
        Line.Insert();
        Line."Line No." := 40000;
        Line.Qty := 4;
        Line.Amt := 4;
        Line.Insert();
        Log.Reset();
    end;

    [Test]
    procedure QL_Both_NewPartRow_PartModifiesHost()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-qty-after-part', TP.Lines.QtyF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QL_SubPart_NewPartRow_PartModifiesHost()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-qty-after-part', TP.Lines.QtyF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Default_NewPartRow_PartModifiesHost()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Log.Take();
        TP.Lines.Last();
        TP.Lines.New();
        Observer.Observe('log-new', Log.Take());
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('part-line-after-part', TP.Lines.LineNoF.Value());
        Observer.Observe('part-qty-after-part', TP.Lines.QtyF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('stored-after-close', Stored());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Both_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QL_SubPart_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host SubPart";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Default_PartUpdate_HostRowUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QL Note Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.AmtF.SetValue(5);
        Observer.Observe('log-part-edit', Log.Take());
        Observer.Observe('host-total-after-part', TP.TotalF.Value());
        Observer.Observe('stored-after-part', Stored());
        Observer.Observe('lines-after-part', StoredLines());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLines());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Both_GoToKey_Counts()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Both";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2-again', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey-h1', Log.Take());
        Observer.Observe('part-line-at-h1', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure QL_Default_GoToKey_Counts()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        SeedQl();
        TP.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2-again', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey-h1', Log.Take());
        Observer.Observe('part-line-at-h1', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure QL_OpenView_GoToKey_Counts()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Host Default";
    begin
        SeedQl();
        TP.OpenView();
        Observer.Observe('log-open', Log.Take());
        TP.GoToKey('H2');
        Observer.Observe('log-gotokey-h2', Log.Take());
        TP.GoToKey('H1');
        Observer.Observe('log-gotokey-h1', Log.Take());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure QL_PartNew_WithoutLast()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-1-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H1'));
        Observer.Finish();
    end;

    [Test]
    procedure QL_PartLastNew_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-1-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure QL_PartFirstNew_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H2');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('first-result', Format(TP.Lines.First()));
        Observer.Observe('log-1-first', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure QL_PartLastNew_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H3');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-1-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H3'));
        Observer.Finish();
    end;

    [Test]
    procedure QL_PartLastNewNew()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT QJ Save Host";
    begin
        SeedQl();
        TP.OpenEdit();
        TP.GoToKey('H1');
        Observer.Observe('log-open', Log.Take());
        Observer.Observe('last-result', Format(TP.Lines.Last()));
        Observer.Observe('log-1-last', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-2-new', Log.Take());
        TP.Lines.New();
        Observer.Observe('log-3-new', Log.Take());
        Observer.Observe('part-line', TP.Lines.LineNoF.Value());
        TP.Close();
        Observer.Observe('log-close', Log.Take());
        Observer.Observe('lines-after-close', StoredLinesOf('H1'));
        Observer.Finish();
    end;

    local procedure StoredLinesOf(DocNo: Code[20]): Text
    var
        Line: Record "LT QJ Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", DocNo);
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Format(Line."Line No.") + ':q=' + Format(Line.Qty) + ',a=' + Format(Line.Amt);
            until Line.Next() = 0;
        exit(Result);
    end;
}
