// Batch 6, md:348 [AllObj, AllObjWithCaption] "AL namespace" columns. The column name is not known, so the test finds every column whose name contains
// "amespace" and reads it for an object in a namespace, an object with no namespace, and a Base Application object. Observe-only.

using W6Probe.Names;

codeunit 67324 "W6 NS Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NamespaceColumns(TableId: Integer; ObjectTypeOrdinal: Integer; ObjectId: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
        Found: Integer;
    begin
        RecRef.Open(TableId);
        RecRef.Field(1).SetRange(ObjectTypeOrdinal);
        RecRef.Field(2).SetRange(ObjectId);
        if not RecRef.FindFirst() then begin
            Observer.Observe(Prefix + '_row', 'no row');
            exit;
        end;
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Name().Contains('amespace') then begin
                Found += 1;
                Observer.Observe(Prefix + '_column_' + Format(FldRef.Number()) + '_' + FldRef.Name(), Format(FldRef.Value()));
            end;
        end;
        Observer.Observe(Prefix + '_namespace_column_count', Format(Found));
    end;

}
