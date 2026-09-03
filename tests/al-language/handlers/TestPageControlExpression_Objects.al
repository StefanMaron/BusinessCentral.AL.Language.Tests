// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: (none — the table below is the card page's SourceTable)
//
// Backing objects for the control-property-expression suite. Visible, Editable and Enabled on a
// page control accept an AL client expression, not only a variable name. The AL compiler limits
// what may appear in one: a procedure call is rejected with
//
//     AL0322: Procedure calls is not valid for client expressions.
//             Client expressions can only use simple data types and field references.
//
// so the grammar is literals, page globals, source-table field references, `not`, `and` / `or`,
// the comparison operators, and parentheses. Every control below is one shape from that grammar.
// None of them is a compile-time literal, so none is dead-code-eliminated: each control exists on
// the runtime page and its property is evaluated live on every read.
//
// ToggleHide and ToggleLock are page-variable-bound controls the tests flip with SetValue to move
// HideIt and LockIt between false and true. ToggleFlag is bound to the source table's Boolean
// field, which is what drives the two Rec-field-reference controls.

table 60257 "TPCE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Value; Text[30]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}

page 60258 "TPCE Card"
{
    PageType = Card;
    SourceTable = "TPCE Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPCE Card';

    layout
    {
        area(Content)
        {
            // A single page global on its own. The baseline: this shape already works everywhere,
            // and every test below that reads NotGlobal reads this one too, so a fix that broke
            // the simple case could not pass the suite.
            field(PlainGlobal; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Plain Global';
                Visible = HideIt;
            }

            field(NotGlobal; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Not Global';
                Visible = not HideIt;
            }

            field(AndGlobals; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'And Globals';
                Visible = HideIt and LockIt;
            }

            field(OrGlobals; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Or Globals';
                Visible = HideIt or LockIt;
            }

            field(NotParenthesized; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Not Parenthesized';
                Visible = not (HideIt or LockIt);
            }

            field(RecFieldRef; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Rec Field Ref';
                Visible = Rec.Flag;
            }

            field(NotRecFieldRef; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Not Rec Field Ref';
                Visible = not Rec.Flag;
            }

            field(Comparison; Rec.PK)
            {
                ApplicationArea = All;
                Caption = 'Comparison';
                Visible = Rec.Value <> '';
            }

            field(NotEditable; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Not Editable';
                Editable = not LockIt;
            }

            field(NotEnabled; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Not Enabled';
                Enabled = not LockIt;
            }

            field(ToggleHide; HideIt)
            {
                ApplicationArea = All;
                Caption = 'Toggle Hide';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }

            field(ToggleLock; LockIt)
            {
                ApplicationArea = All;
                Caption = 'Toggle Lock';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }

            field(ToggleFlag; Rec.Flag)
            {
                ApplicationArea = All;
                Caption = 'Toggle Flag';
            }

            // Bound to a global that OnOpenPage sets from the record, so its value at open time
            // is decided by which row the page opened on.
            field(OpenTimeGlobal; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Open Time Global';
                Visible = OpenTimeFlag;
            }

            field(NotOpenTimeGlobal; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Not Open Time Global';
                Visible = not OpenTimeFlag;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Set from the record the page opened on, so a test can control this global's value at
        // open time without needing a later change to be observable.
        OpenTimeFlag := Rec.Flag;
    end;

    var
        HideIt: Boolean;
        LockIt: Boolean;
        OpenTimeFlag: Boolean;
}
