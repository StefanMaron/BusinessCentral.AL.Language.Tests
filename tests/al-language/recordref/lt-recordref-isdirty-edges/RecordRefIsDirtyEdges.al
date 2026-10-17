// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 71765, 71766, test codeunit 71767
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.IsDirty edge cases. Two RecordRefs on the same row where one modifies (is dirty measured against the row as read or against the stored row); IsDirty after SetLoadFields
// and a partial FindFirst, after changing a loaded and then an unloaded field; IsDirty on a table with a FlowField after FieldRef.CalcField. The basic cases are in P92DirtyRef.al and P107RecRefNames.al.
// BC versions: 29 (27 and 28 by CI)

#if BC28PLUS
table 71765 "LT RD Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Note; Text[30]) { }
        field(5; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT RD Line".Amount where(ItemId = field(Id)));
            Editable = false;
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 71766 "LT RD Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ItemId; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 71767 "LT RecRef IsDirty Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT RD Item";
        Line: Record "LT RD Line";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Item.Id := 1;
        Item.Name := 'one';
        Item.Qty := 10;
        Item.Note := 'n1';
        Item.Insert();
        Line.Id := 1;
        Line.ItemId := 1;
        Line.Amount := 5;
        Line.Insert();
        Line.Id := 2;
        Line.ItemId := 1;
        Line.Amount := 7;
        Line.Insert();
    end;

    [Test]
    procedure IsDirty_TwoRefs_OtherModifies()
    var
        Observer: Codeunit "Probe Observer";
        Ref1: RecordRef;
        Ref2: RecordRef;
    begin
        Seed();
        Ref1.Open(71765);
        Ref2.Open(71765);
        Ref1.FindFirst();
        Ref2.FindFirst();
        Ref1.Field(2).Value := 'changed';
        Observer.Observe('r1_after_set', Format(Ref1.IsDirty()));
        Observer.Observe('r2_after_r1_set', Format(Ref2.IsDirty()));
        Ref1.Modify();
        Observer.Observe('r1_after_modify', Format(Ref1.IsDirty()));
        Observer.Observe('r2_after_r1_modify', Format(Ref2.IsDirty()));
        Observer.Observe('r2_name_still', Format(Ref2.Field(2).Value));
        Ref2.Field(2).Value := 'one';
        Observer.Observe('r2_set_value_it_read', Format(Ref2.IsDirty()));
        Ref2.Field(2).Value := 'changed';
        Observer.Observe('r2_set_value_stored', Format(Ref2.IsDirty()));
        Ref2.Field(2).Value := 'third';
        Observer.Observe('r2_set_third', Format(Ref2.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_TwoRefs_OtherModifiesDifferentField()
    var
        Observer: Codeunit "Probe Observer";
        Ref1: RecordRef;
        Ref2: RecordRef;
    begin
        Seed();
        Ref1.Open(71765);
        Ref2.Open(71765);
        Ref1.FindFirst();
        Ref2.FindFirst();
        Ref1.Field(3).Value := 99;
        Ref1.Modify();
        Ref2.Field(2).Value := 'two';
        Observer.Observe('r2_dirty', Format(Ref2.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_TwoRefs_StaleModify()
    var
        Observer: Codeunit "Probe Observer";
        Ref1: RecordRef;
        Ref2: RecordRef;
        Stored: Record "LT RD Item";
    begin
        Seed();
        Ref1.Open(71765);
        Ref2.Open(71765);
        Ref1.FindFirst();
        Ref2.FindFirst();
        Ref1.Field(3).Value := 99;
        Ref1.Modify();
        Ref2.Field(2).Value := 'two';
        asserterror Ref2.Modify();
        Observer.ObserveError('stale_modify');
        Observer.Observe('r2_dirty_after', Format(Ref2.IsDirty()));
        Stored.Get(1);
        Observer.Observe('stored_qty', Format(Stored.Qty));
        Observer.Observe('stored_name', Stored.Name);
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_TwoRefs_ModifyAfterRefind()
    var
        Observer: Codeunit "Probe Observer";
        Ref1: RecordRef;
        Ref2: RecordRef;
        Stored: Record "LT RD Item";
    begin
        Seed();
        Ref1.Open(71765);
        Ref2.Open(71765);
        Ref1.FindFirst();
        Ref2.FindFirst();
        Ref1.Field(3).Value := 99;
        Ref1.Modify();
        Ref2.FindFirst();
        Observer.Observe('r2_qty_after_refind', Format(Ref2.Field(3).Value));
        Observer.Observe('r2_dirty_after_refind', Format(Ref2.IsDirty()));
        Ref2.Field(2).Value := 'two';
        Ref2.Modify();
        Stored.Get(1);
        Observer.Observe('stored_qty', Format(Stored.Qty));
        Observer.Observe('stored_name', Stored.Name);
        Observer.Observe('r2_dirty_after_modify', Format(Ref2.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_SetLoadFields_LoadedFieldChanges()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Seed();
        Ref.Open(71765);
        Ref.SetLoadFields(2);
        Ref.FindFirst();
        Observer.Observe('after_find', Format(Ref.IsDirty()));
        Ref.Field(2).Value := 'one';
        Observer.Observe('loaded_same', Format(Ref.IsDirty()));
        Ref.Field(2).Value := 'changed';
        Observer.Observe('loaded_changed', Format(Ref.IsDirty()));
        Ref.Field(3).Value := 10;
        Observer.Observe('then_unloaded_same_as_stored', Format(Ref.IsDirty()));
        Ref.Field(3).Value := 11;
        Observer.Observe('then_unloaded_changed', Format(Ref.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_SetLoadFields_UnloadedFieldFirst()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Seed();
        Ref.Open(71765);
        Ref.SetLoadFields(2);
        Ref.FindFirst();
        Ref.Field(3).Value := 10;
        Observer.Observe('unloaded_same_as_stored', Format(Ref.IsDirty()));
        Ref.Field(4).Value := 'other';
        Observer.Observe('unloaded_changed', Format(Ref.IsDirty()));
        Ref.Field(4).Value := 'n1';
        Observer.Observe('unloaded_back_to_stored', Format(Ref.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_SetLoadFields_ReadUnloadedThenCompare()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Seed();
        Ref.Open(71765);
        Ref.SetLoadFields(2);
        Ref.FindFirst();
        Observer.Observe('read_unloaded', Format(Ref.Field(3).Value));
        Observer.Observe('after_read', Format(Ref.IsDirty()));
        Ref.Field(3).Value := 10;
        Observer.Observe('set_same', Format(Ref.IsDirty()));
        Ref.Field(3).Value := 12;
        Observer.Observe('set_other', Format(Ref.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_SetLoadFields_ModifyPartialRow()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Stored: Record "LT RD Item";
    begin
        Seed();
        Ref.Open(71765);
        Ref.SetLoadFields(2);
        Ref.FindFirst();
        Ref.Field(2).Value := 'partial';
        Ref.Modify();
        Observer.Observe('after_modify', Format(Ref.IsDirty()));
        Stored.Get(1);
        Observer.Observe('name', Stored.Name);
        Observer.Observe('qty', Format(Stored.Qty));
        Observer.Observe('note', Stored.Note);
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_FlowField_AfterCalcField()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Seed();
        Ref.Open(71765);
        Ref.FindFirst();
        Observer.Observe('after_find', Format(Ref.IsDirty()));
        Ref.Field(5).CalcField();
        Observer.Observe('after_calc', Format(Ref.IsDirty()));
        Observer.Observe('total', Format(Ref.Field(5).Value));
        Ref.Field(3).Value := 11;
        Observer.Observe('then_qty_changed', Format(Ref.IsDirty()));
        Ref.Field(3).Value := 10;
        Observer.Observe('then_qty_back', Format(Ref.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_FlowField_ChangeUnderneathThenCalc()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
        Line: Record "LT RD Line";
    begin
        Seed();
        Ref.Open(71765);
        Ref.FindFirst();
        Ref.Field(5).CalcField();
        Line.Get(1);
        Line.Amount := 100;
        Line.Modify();
        Ref.Field(5).CalcField();
        Observer.Observe('after_second_calc', Format(Ref.IsDirty()));
        Observer.Observe('total', Format(Ref.Field(5).Value));
        Ref.Modify();
        Observer.Observe('after_modify', Format(Ref.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure IsDirty_FlowField_WithoutCalc()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Seed();
        Ref.Open(71765);
        Ref.FindFirst();
        Observer.Observe('flow_value_uncalculated', Format(Ref.Field(5).Value));
        Observer.Observe('after_reading_flow', Format(Ref.IsDirty()));
        Ref.SetAutoCalcFields(5);
        Ref.FindFirst();
        Observer.Observe('autocalc_total', Format(Ref.Field(5).Value));
        Observer.Observe('autocalc_dirty', Format(Ref.IsDirty()));
        Observer.Finish();
    end;
}
#endif
