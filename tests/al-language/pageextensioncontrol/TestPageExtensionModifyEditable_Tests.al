// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021).
//
// CLAIM: the source-compiled twin of codeunit 68620. When a pageextension uses modify(<control>)
// or modify(<action>) to set Editable or Enabled on an element of a page compiled in the SAME app,
// TestPage answers the EXTENSION's property, evaluated against a variable the extension owns and
// sets in its own OnAfterGetCurrRecord from a related record (a "PXMS Lock" row with the same
// code). The base page declares no Editable on NameCtl and its own Editable = BaseEditable (always
// true) on FlagCtl; the extension sets both to `not PXMSLocked`. OtherCtl's Enabled and the DoIt
// action's Enabled are modified the same way. PlainCtl is not modified and stays editable.
//
// One test walks a locked row and an unlocked row on one open page, so an answer of false (or
// true) for every row fails it.
//
// Written by agent stma-auto-8, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5139.

table 68620 "PXMS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Flag; Boolean) { }
        field(4; Other; Text[30]) { }
        field(5; Plain; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 68621 "PXMS Lock"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 68620 "PXMS Card"
{
    PageType = Card;
    SourceTable = "PXMS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(FlagCtl; Rec.Flag) { ApplicationArea = All; Editable = BaseEditable; }
            field(OtherCtl; Rec.Other) { ApplicationArea = All; }
            field(PlainCtl; Rec.Plain) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DoIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        BaseEditable: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        BaseEditable := true;
    end;
}

pageextension 68621 "PXMS Card Ext" extends "PXMS Card"
{
    layout
    {
        modify(NameCtl) { Editable = not PXMSLocked; }
        modify(FlagCtl) { Editable = not PXMSLocked; }
        modify(OtherCtl) { Enabled = not PXMSLocked; }
    }

    actions
    {
        modify(DoIt) { Enabled = not PXMSLocked; }
    }

    var
        PXMSLocked: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        Lock: Record "PXMS Lock";
    begin
        PXMSLocked := Lock.Get(Rec.Code);
    end;
}

codeunit 68621 "PXMS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SourcePageExtModifyEditable_SourcePage_FollowsTheExtensionsVariablePerRow()
    var
        Row: Record "PXMS Row";
        Lock: Record "PXMS Lock";
        Card: TestPage "PXMS Card";
    begin
        Row.DeleteAll();
        Lock.DeleteAll();
        Row.Code := 'LOCKED';
        Row.Insert();
        Row.Code := 'OPEN';
        Row.Insert();
        Lock.Code := 'LOCKED';
        Lock.Insert();

        Card.OpenEdit();
        Row.Get('LOCKED');
        Assert.IsTrue(Card.GoToRecord(Row), 'GoToRecord must position the card on LOCKED.');
        Assert.IsTrue(Card.PlainCtl.Editable(), 'PlainCtl, which the pageextension does not modify, must stay editable on LOCKED.');
        Assert.IsFalse(Card.NameCtl.Editable(), 'NameCtl (Editable = not PXMSLocked set by modify()) must be read-only on LOCKED.');
        Assert.IsFalse(Card.FlagCtl.Editable(), 'FlagCtl (own Editable = BaseEditable; Editable = not PXMSLocked set by modify()) must be read-only on LOCKED.');
        Assert.IsFalse(Card.OtherCtl.Enabled(), 'OtherCtl (Enabled = not PXMSLocked set by modify()) must be disabled on LOCKED.');
        Assert.IsFalse(Card.DoIt.Enabled(), 'Action DoIt (Enabled = not PXMSLocked set by modify()) must be disabled on LOCKED.');

        Row.Get('OPEN');
        Assert.IsTrue(Card.GoToRecord(Row), 'GoToRecord must position the card on OPEN.');
        Assert.IsTrue(Card.NameCtl.Editable(), 'NameCtl must be editable on OPEN.');
        Assert.IsTrue(Card.FlagCtl.Editable(), 'FlagCtl must be editable on OPEN.');
        Assert.IsTrue(Card.OtherCtl.Enabled(), 'OtherCtl must be enabled on OPEN.');
        Assert.IsTrue(Card.DoIt.Enabled(), 'Action DoIt must be enabled on OPEN.');
        Card.Close();
    end;
}
