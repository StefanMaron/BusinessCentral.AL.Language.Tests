// Probe (observe only): CurrFieldNo in nested validates, other records and table procedures during a TestPage write; table extension modify(Field) OnBeforeValidate /
// OnAfterValidate order with two extensions on the same field, with an event subscriber, and for a page edit.
// Settles docs/probes-needed.md rows 297 (the arms the corpus does not pin) and 328 (open half: two extensions on one field, page-edit validation) (batch 4).
// Object ids 68059 - 68071. Both log codeunits are SingleInstance and each belongs to exactly one test codeunit.

// ---------------------------------------------------------------- CurrFieldNo
// ---------------------------------------------------------------- table extension validate order
table 68063 "W4 TE Base"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('base.onvalidate');
            end;
        }
    }
    keys { key(PK; Id) { Clustered = true; } }

    var
        Log: Codeunit "W4 TE Log";
}


table 68059 "W4 CFN Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Code[10]) { }
        field(10; A; Integer)
        {
            trigger OnValidate()
            var
                Other: Record "W4 CFN Row";
            begin
                Log.Add('A.validate cur=' + Format(CurrFieldNo));
                Rec.Validate(B, 7);
                Helper();
                Other.Id := 'ZZ';
                Other.Validate(B, 1);
            end;
        }
        field(20; B; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('B.validate id=' + Id + ' cur=' + Format(CurrFieldNo));
            end;
        }
        field(30; C; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    var
        Log: Codeunit "W4 CFN Log";

    trigger OnInsert()
    begin
        Log.Add('insert cur=' + Format(CurrFieldNo));
    end;

    trigger OnModify()
    begin
        Log.Add('modify cur=' + Format(CurrFieldNo));
    end;

    procedure Helper()
    begin
        Log.Add('helper cur=' + Format(CurrFieldNo));
    end;
}

codeunit 68060 "W4 CFN Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Line: Text)
    begin
        Text += Line + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Text;
        Text := '';
    end;
}

page 68061 "W4 CFN Card"
{
    PageType = Card;
    SourceTable = "W4 CFN Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(A; Rec.A) { ApplicationArea = All; }
            field(B; Rec.B) { ApplicationArea = All; }
            field(C; Rec.C) { ApplicationArea = All; }
        }
    }
}

codeunit 68062 "W4 CFN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W4 CFN Log";

    local procedure MakeRow(Id: Code[10])
    var
        Row: Record "W4 CFN Row";
    begin
        Row.DeleteAll();
        Row.Id := Id;
        Row.Insert();
        Log.Take();
    end;

    [Test]
    procedure PageWrite_NestedValidateOtherRecordAndHelper()
    var
        Row: Record "W4 CFN Row";
        Card: TestPage "W4 CFN Card";
        Observer: Codeunit "Probe Observer";
    begin
        MakeRow('R1');
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.A.SetValue(5);
        Observer.Observe('after_set_a', Log.Take());
        Card.C.SetValue(2);
        Observer.Observe('after_set_c', Log.Take());
        Card.B.SetValue(9);
        Observer.Observe('after_set_b', Log.Take());
        Card.Close();
        Observer.Observe('after_close', Log.Take());
        Row.DeleteAll();
        Observer.Expect('after_set_a', 'A.validate cur=10;B.validate id=R1 cur=10;helper cur=10;B.validate id=ZZ cur=0;');
        Observer.Expect('after_set_c', '');
        Observer.Expect('after_set_b', 'B.validate id=R1 cur=20;');
        Observer.Expect('after_close', 'modify cur=0;');
        Observer.Verify();
    end;

    [Test]
    procedure ValidateFromCode_NestedValidateOtherRecordAndHelper()
    var
        Row: Record "W4 CFN Row";
        Observer: Codeunit "Probe Observer";
    begin
        MakeRow('R2');
        Row.Get('R2');
        Row.Validate(A, 5);
        Observer.Observe('after_validate_a', Log.Take());
        Row.Validate(C, 2);
        Observer.Observe('after_validate_c', Log.Take());
        Row.Modify(true);
        Observer.Observe('after_modify', Log.Take());
        Row.DeleteAll();
        Observer.Expect('after_validate_a', 'A.validate cur=0;B.validate id=R2 cur=0;helper cur=0;B.validate id=ZZ cur=0;');
        Observer.Expect('after_validate_c', '');
        Observer.Expect('after_modify', 'modify cur=0;');
        Observer.Verify();
    end;

    [Test]
    procedure PageWrite_NewRecord_InsertTrigger()
    var
        Row: Record "W4 CFN Row";
        Card: TestPage "W4 CFN Card";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Log.Take();
        Card.OpenNew();
        Card.Id.SetValue('N1');
        Observer.Observe('after_set_id', Log.Take());
        Card.A.SetValue(3);
        Observer.Observe('after_set_a', Log.Take());
        Card.Close();
        Observer.Observe('after_close', Log.Take());
        Observer.Observe('row_exists', Format(Row.Get('N1')));
        Row.DeleteAll();
        Observer.Expect('after_set_id', '');
        Observer.Expect('after_set_a', 'insert cur=0;A.validate cur=10;B.validate id=N1 cur=10;helper cur=10;B.validate id=ZZ cur=0;');
        Observer.Expect('after_close', 'modify cur=0;');
        Observer.Expect('row_exists', 'Yes');
        Observer.Verify();
    end;
}

codeunit 68064 "W4 TE Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Line: Text)
    begin
        Text += Line + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Text;
        Text := '';
    end;
}

tableextension 68065 "W4 TE Ext One" extends "W4 TE Base"
{
    fields
    {
        modify(Val)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W4 TE Log";
            begin
                Log.Add('ext1.before');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W4 TE Log";
            begin
                Log.Add('ext1.after');
            end;
        }
    }
}

tableextension 68066 "W4 TE Ext Two" extends "W4 TE Base"
{
    fields
    {
        modify(Val)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W4 TE Log";
            begin
                Log.Add('ext2.before');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W4 TE Log";
            begin
                Log.Add('ext2.after');
            end;
        }
    }
}

page 68067 "W4 TE Card"
{
    PageType = Card;
    SourceTable = "W4 TE Base";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Val; Rec.Val) { ApplicationArea = All; }
        }
    }
}

// Manual subscribers: they run only while a test binds an instance.
codeunit 68068 "W4 TE Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"W4 TE Base", 'OnBeforeValidateEvent', 'Val', false, false)]
    local procedure OnBeforeValidateVal(var Rec: Record "W4 TE Base"; var xRec: Record "W4 TE Base"; CurrFieldNo: Integer)
    var
        Log: Codeunit "W4 TE Log";
    begin
        Log.Add('event.before');
    end;

    [EventSubscriber(ObjectType::Table, Database::"W4 TE Base", 'OnAfterValidateEvent', 'Val', false, false)]
    local procedure OnAfterValidateVal(var Rec: Record "W4 TE Base"; var xRec: Record "W4 TE Base"; CurrFieldNo: Integer)
    var
        Log: Codeunit "W4 TE Log";
    begin
        Log.Add('event.after');
    end;
}

codeunit 68069 "W4 TE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "W4 TE Log";

    [Test]
    procedure TwoExtensions_ValidateFromCode()
    var
        Row: Record "W4 TE Base";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Row.Validate(Val, 3);
        Observer.Observe('validate_from_code', Log.Take());
        Row.Val := 4;
        Observer.Observe('plain_assignment', '[' + Log.Take() + ']');
        Observer.Expect('validate_from_code', 'ext1.before;ext2.before;base.onvalidate;ext1.after;ext2.after;');
        Observer.Expect('plain_assignment', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure TwoExtensions_WithEventSubscriber()
    var
        Row: Record "W4 TE Base";
        Subs: Codeunit "W4 TE Subs";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        BindSubscription(Subs);
        Row.Validate(Val, 3);
        UnbindSubscription(Subs);
        Observer.Observe('validate_with_subscriber', Log.Take());
        Observer.Expect('validate_with_subscriber', 'event.before;ext1.before;ext2.before;base.onvalidate;ext1.after;ext2.after;event.after;');
        Observer.Verify();
    end;

    [Test]
    procedure TwoExtensions_PageEdit()
    var
        Row: Record "W4 TE Base";
        Card: TestPage "W4 TE Card";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Val.SetValue(6);
        Observer.Observe('page_edit', Log.Take());
        Card.Close();
        Row.DeleteAll();
        Observer.Expect('page_edit', 'ext1.before;ext2.before;base.onvalidate;ext1.after;ext2.after;');
        Observer.Verify();
    end;

    [Test]
    procedure TwoExtensions_PageEdit_WithEventSubscriber()
    var
        Row: Record "W4 TE Base";
        Card: TestPage "W4 TE Card";
        Subs: Codeunit "W4 TE Subs";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        BindSubscription(Subs);
        Log.Take();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Val.SetValue(6);
        Observer.Observe('page_edit_with_subscriber', Log.Take());
        Card.Close();
        UnbindSubscription(Subs);
        Row.DeleteAll();
        Observer.Expect('page_edit_with_subscriber', 'event.before;ext1.before;ext2.before;base.onvalidate;ext1.after;ext2.after;event.after;');
        Observer.Verify();
    end;
}
