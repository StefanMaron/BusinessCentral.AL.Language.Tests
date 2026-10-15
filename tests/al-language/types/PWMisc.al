// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-copy-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// - ClientType members on this tier (ordinal=name): 0 Current, 1 Default, 2 Windows, 3 Web, 4 SOAP, 5 OData, 6 NAS, 7 Background, 8 Management, 9 Tablet, 10 Phone, 11 Desktop, 12 Teams,
//   13 ODataV4, 14 Api, 15 ChildSession (nothing above 15).
// - A field with ObsoleteState = Moved (MovedTo another app) has NO row in the Field table (the lookup finds nothing); a field with ObsoleteState = Pending has one, Enabled Yes.
// - RecordRef.Copy(RecRef) into a RecordRef that was never opened raises "The record is not open." / RecordNotOpened; into an opened one it takes the source's filters and current row;
//   Copy(RecRef, true) (ShareTable) is accepted only when both records are temporary, otherwise "The COPY function can only be used with the shareTable argument set to true if both records
//   are temporary." For temporary records the copy shares the table: a row inserted through the copy is counted by the source (2 rows), a copy without ShareTable starts with 0 rows.
// Fixtures used: self-contained table 69342, codeunit 69342
// BC versions: 27.5, 29.0

table 69342 "PX2 Moved Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Gone; Text[30])
        {
            ObsoleteState = Moved;
            ObsoleteReason = 'Moved to another app';
            ObsoleteTag = '1.0';
            MovedTo = '11111111-2222-3333-4444-555555555555';
        }
        field(4; Pending; Text[30])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Pending removal';
            ObsoleteTag = '1.0';
        }
    }

    keys { key(PK; Id) { Clustered = true; } key(Sec; Name) { } }
}

codeunit 69342 "PX2 Misc Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClientType_OrdinalsAndNames()
    var
        CT: ClientType;
        Ok: Boolean;
        i: Integer;
        Names: Text;
        Observer: Codeunit "Probe Observer";
    begin
        for i := 0 to 30 do begin
            Ok := Evaluate(CT, Format(i));
            if Ok then
                Names += Format(i) + '=' + Format(CT) + ' ';
        end;
        Observer.Observe('ordinal_names', Names);
        Observer.Expect('ordinal_names', '0=Current 1=Default 2=Windows 3=Web 4=SOAP 5=OData 6=NAS 7=Background 8=Management 9=Tablet 10=Phone 11=Desktop 12=Teams 13=ODataV4 14=Api 15=ChildSession ');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_MovedAndPendingField()
    var
        FieldRec: Record Field;
        Observer: Codeunit "Probe Observer";
    begin
        FieldRec.SetRange(TableNo, Database::"PX2 Moved Row");
        FieldRec.SetRange("No.", 3);
        Observer.Observe('moved_found', Format(FieldRec.FindFirst()));
        if FieldRec.FindFirst() then begin
            Observer.Observe('moved_obsolete_state', Format(FieldRec.ObsoleteState));
            Observer.Observe('moved_enabled', Format(FieldRec.Enabled));
            Observer.Observe('moved_class', Format(FieldRec.Class));
            Observer.Observe('moved_name', FieldRec.FieldName);
            Observer.Observe('moved_type', Format(FieldRec.Type));
            Observer.Observe('moved_len', Format(FieldRec.Len));
        end;
        FieldRec.SetRange("No.", 4);
        if FieldRec.FindFirst() then begin
            Observer.Observe('pending_obsolete_state', Format(FieldRec.ObsoleteState));
            Observer.Observe('pending_enabled', Format(FieldRec.Enabled));
        end;
        Observer.Expect('moved_found', 'No');
        Observer.Expect('pending_obsolete_state', 'Pending');
        Observer.Expect('pending_enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Copy_ToAnUnopenedRecordRef()
    var
        Row: Record "PX2 Moved Row";
        Src: RecordRef;
        Dst: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Src.Open(Database::"PX2 Moved Row");
        asserterror Dst.Copy(Src);
        Observer.ObserveError('copy_to_unopened');
        Observer.Expect('copy_to_unopened|text', 'The record is not open.');
        Observer.Expect('copy_to_unopened|code', 'RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Copy_Forms()
    var
        Row: Record "PX2 Moved Row";
        Src: RecordRef;
        Dst: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Src.Open(Database::"PX2 Moved Row");
        Src.Field(2).SetRange('two');
        Src.FindFirst();
        Dst.Open(Database::"PX2 Moved Row");
        Dst.Copy(Src);
        Observer.Observe('copy_filters', Dst.GetFilters());
        Observer.Observe('copy_current_row_id', Format(Dst.Field(1).Value));
        Observer.Observe('copy_count_filtered', Format(Dst.Count()));
        Dst.Reset();
        Observer.Observe('copy_reset_keeps_source_filter', Src.GetFilters());
        Dst.Copy(Src);
        Dst.Field(1).Value := 99;
        Observer.Observe('copy_independent_buffer_source_id', Format(Src.Field(1).Value));
        Clear(Dst);
        Dst.Open(Database::"PX2 Moved Row");
        asserterror Dst.Copy(Src, true);
        Observer.ObserveError('copy_sharetable_true_persistent');
        Observer.Expect('copy_filters', 'Name: two');
        Observer.Expect('copy_current_row_id', '2');
        Observer.Expect('copy_count_filtered', '1');
        Observer.Expect('copy_reset_keeps_source_filter', 'Name: two');
        Observer.Expect('copy_independent_buffer_source_id', '2');
        Observer.Expect('copy_sharetable_true_persistent|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('copy_sharetable_true_persistent|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Copy_Temporary_ShareTable()
    var
        Tmp: Record "PX2 Moved Row" temporary;
        Src: RecordRef;
        Dst: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Tmp.Id := 1;
        Tmp.Name := 'tmp';
        Tmp.Insert();
        Src.GetTable(Tmp);
        Dst.Open(Database::"PX2 Moved Row", true);
        Dst.Copy(Src, true);
        Observer.Observe('shared_is_temporary', Format(Dst.IsTemporary()));
        Observer.Observe('shared_count', Format(Dst.Count()));
        Dst.Field(1).Value := 5;
        Dst.Field(2).Value := 'added';
        Dst.Insert();
        Observer.Observe('count_in_source_after_insert_through_copy', Format(Tmp.Count()));
        Clear(Dst);
        Dst.Open(Database::"PX2 Moved Row", true);
        Dst.Copy(Src, false);
        Observer.Observe('not_shared_count', Format(Dst.Count()));
        Observer.Expect('shared_is_temporary', 'Yes');
        Observer.Expect('shared_count', '1');
        Observer.Expect('count_in_source_after_insert_through_copy', '2');
        Observer.Expect('not_shared_count', '0');
        Observer.Verify();
    end;
}
