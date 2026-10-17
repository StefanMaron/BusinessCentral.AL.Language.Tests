// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74868, page 74868, test codeunit 74894
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: TestPage field Editable() for a control over a table field with Editable = false, with the control having no Editable property, Editable = true,
//   Editable = false, and Enabled = false; the same page opened with OpenEdit, OpenView and OpenNew, and a page with Editable = false.
//   Then SetValue on the non-editable field: the error text and code, or no error. Settles the assumption page-field-follows-source-field-editable-false.
// BC versions: all (CI)

table 74868 "LT PFE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Locked; Text[30]) { Editable = false; }
        field(3; Plain; Text[30]) { }
        field(4; LockedAgain; Text[30]) { Editable = false; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 74868 "LT PFE Card"
{
    PageType = Card;
    SourceTable = "LT PFE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(LockedNoProp; Rec.Locked) { ApplicationArea = All; }
            field(LockedEditableTrue; Rec.LockedAgain) { ApplicationArea = All; Editable = true; }
            field(PlainNoProp; Rec.Plain) { ApplicationArea = All; }
            field(PlainEditableFalse; Rec.Plain) { ApplicationArea = All; Editable = false; }
            field(PlainEnabledFalse; Rec.Plain) { ApplicationArea = All; Enabled = false; }
        }
    }
}

page 74869 "LT PFE ReadOnly Card"
{
    PageType = Card;
    SourceTable = "LT PFE Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(PlainNoProp; Rec.Plain) { ApplicationArea = All; }
            field(LockedEditableTrue; Rec.LockedAgain) { ApplicationArea = All; Editable = true; }
        }
    }
}

codeunit 74894 "LT PFE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prepare()
    var
        Row: Record "LT PFE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'R1';
        Row.Locked := 'locked';
        Row.Insert();
    end;

    [Test]
    procedure Card_OpenEdit_FieldEditable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE Card";
    begin
        Prepare();
        TP.OpenEdit();
        Observer.Observe('code', Format(TP."Code".Editable()));
        Observer.Observe('lockedNoProp', Format(TP.LockedNoProp.Editable()));
        Observer.Observe('lockedEditableTrue', Format(TP.LockedEditableTrue.Editable()));
        Observer.Observe('plainNoProp', Format(TP.PlainNoProp.Editable()));
        Observer.Observe('plainEditableFalse', Format(TP.PlainEditableFalse.Editable()));
        Observer.Observe('plainEnabledFalse', Format(TP.PlainEnabledFalse.Editable()));
        Observer.Observe('lockedEnabled', Format(TP.LockedNoProp.Enabled()));
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenView_FieldEditable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE Card";
    begin
        Prepare();
        TP.OpenView();
        Observer.Observe('code', Format(TP."Code".Editable()));
        Observer.Observe('lockedNoProp', Format(TP.LockedNoProp.Editable()));
        Observer.Observe('lockedEditableTrue', Format(TP.LockedEditableTrue.Editable()));
        Observer.Observe('plainNoProp', Format(TP.PlainNoProp.Editable()));
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenNew_FieldEditable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE Card";
    begin
        Prepare();
        TP.OpenNew();
        Observer.Observe('code', Format(TP."Code".Editable()));
        Observer.Observe('lockedNoProp', Format(TP.LockedNoProp.Editable()));
        Observer.Observe('lockedEditableTrue', Format(TP.LockedEditableTrue.Editable()));
        Observer.Observe('plainNoProp', Format(TP.PlainNoProp.Editable()));
        Observer.Finish();
    end;

    [Test]
    procedure ReadOnlyCard_OpenEdit_FieldEditable()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE ReadOnly Card";
    begin
        Prepare();
        TP.OpenEdit();
        Observer.Observe('code', Format(TP."Code".Editable()));
        Observer.Observe('plainNoProp', Format(TP.PlainNoProp.Editable()));
        Observer.Observe('lockedEditableTrue', Format(TP.LockedEditableTrue.Editable()));
        Observer.Finish();
    end;

    [Test]
    procedure Card_SetValue_LockedNoProp()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE Card";
    begin
        Prepare();
        TP.OpenEdit();
        asserterror TP.LockedNoProp.SetValue('new');
        Observer.ObserveError('set');
        Observer.Observe('valueAfter', TP.LockedNoProp.Value());
        Observer.Finish();
    end;

    [Test]
    procedure Card_SetValue_PlainEditableFalse()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE Card";
    begin
        Prepare();
        TP.OpenEdit();
        asserterror TP.PlainEditableFalse.SetValue('new');
        Observer.ObserveError('set');
        Observer.Observe('valueAfter', TP.PlainEditableFalse.Value());
        Observer.Finish();
    end;

    [Test]
    procedure Card_SetValue_LockedEditableTrue()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT PFE Card";
    begin
        Prepare();
        TP.OpenEdit();
        asserterror TP.LockedEditableTrue.SetValue('new');
        Observer.ObserveError('set');
        Observer.Observe('valueAfter', TP.LockedEditableTrue.Value());
        Observer.Finish();
    end;
}
