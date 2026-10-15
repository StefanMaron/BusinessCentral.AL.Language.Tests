// Batch 7 probes: Media.ImportStream return value, a second import into the same field, ExportStream of an imported and of an empty field. Observe only.
table 68570 "W7 Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 68571 "W7 Media Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure PngStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(ValidPngBase64, OutS);
        TempBlob.CreateInStream(InS);
    end;

    [Test]
    procedure ImportStream_ReturnValueAndMediaId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Id: Guid;
    begin
        Row.DeleteAll();
        PngStream(TempBlob, InS);
        Row.Code := 'A';
        Observer.Observe('empty field: HasValue', Format(Row.Pic.HasValue()));
        Observer.Observe('empty field: MediaId is null', Format(IsNullGuid(Row.Pic.MediaId())));
        Id := Row.Pic.ImportStream(InS, 'first');
        Observer.Observe('returned id is null', Format(IsNullGuid(Id)));
        Observer.Observe('returned id = MediaId()', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('HasValue before Insert', Format(Row.Pic.HasValue()));
        Row.Insert();
        Observer.Observe('MediaId after Insert is the same', Format(Id = Row.Pic.MediaId()));
        Row.Get('A');
        Observer.Observe('MediaId after Get is the same', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('HasValue after Get', Format(Row.Pic.HasValue()));
        Observer.Expect('empty field: HasValue', 'No');
        Observer.Expect('empty field: MediaId is null', 'Yes');
        Observer.Expect('returned id is null', 'No');
        Observer.Expect('returned id = MediaId()', 'Yes');
        Observer.Expect('HasValue before Insert', 'Yes');
        Observer.Expect('MediaId after Insert is the same', 'Yes');
        Observer.Expect('MediaId after Get is the same', 'Yes');
        Observer.Expect('HasValue after Get', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ImportStream_SecondImportIntoTheSameField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 Media Row";
        Tenant: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        First: Guid;
        Second: Guid;
    begin
        Row.DeleteAll();
        PngStream(TempBlob, InS);
        Row.Code := 'A';
        First := Row.Pic.ImportStream(InS, 'first');
        Row.Insert();
        Clear(TempBlob);
        PngStream(TempBlob, InS);
        Second := Row.Pic.ImportStream(InS, 'second');
        Observer.Observe('second import did not raise', 'true');
        Observer.Observe('second id = first id', Format(Second = First));
        Observer.Observe('MediaId = first id', Format(Row.Pic.MediaId() = First));
        Observer.Observe('MediaId = second id', Format(Row.Pic.MediaId() = Second));
        Observer.Observe('first media still stored', Format(Tenant.Get(First)));
        Observer.Observe('second media stored', Format(Tenant.Get(Second)));
        Observer.Expect('second import did not raise', 'true');
        Observer.Expect('second id = first id', 'No');
        Observer.Expect('MediaId = first id', 'No');
        Observer.Expect('MediaId = second id', 'Yes');
        Observer.Expect('first media still stored', 'Yes');
        Observer.Expect('second media stored', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryExport(var Row: Record "W7 Media Row"; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Row.Pic.ExportStream(OutS);
    end;

    [Test]
    procedure ExportStream_OfAnImportedPicture()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        Row: Record "W7 Media Row";
        Source: Codeunit "Temp Blob";
        Exported: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Row.DeleteAll();
        PngStream(Source, InS);
        Row.Code := 'A';
        Row.Pic.ImportStream(InS, 'first');
        Row.Insert();
        Observer.Observe('export ok', Format(TryExport(Row, Exported)));
        Observer.ObserveError('export');
        Observer.Observe('source length', Format(Source.Length()));
        Observer.Observe('exported length', Format(Exported.Length()));
        Observer.Observe('exported bytes = imported bytes', Format(Util.Hex(Exported) = Util.Hex(Source)));
#if BC29PLUS
        Observer.Observe('exported first bytes', CopyStr(Util.Hex(Exported), 1, 40));
#endif
        Observer.Expect('export ok', 'Yes');
        Observer.Expect('export|text', '');
        Observer.Expect('export|code', '');
        Observer.Expect('source length', '68');
#if BC29PLUS
        Observer.Expect('exported length', '68');
#else
        Observer.Expect('exported length', '93');
#endif
#if BC29PLUS
        Observer.Expect('exported bytes = imported bytes', 'Yes');
        Observer.Expect('exported first bytes', '89 50 4E 47 0D 0A 1A 0A 00 00 00 0D 49 4');
#else
        Observer.Expect('exported bytes = imported bytes', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ExportStream_OfAnEmptyField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 Media Row";
        Exported: Codeunit "Temp Blob";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Insert();
        Observer.Observe('export ok', Format(TryExport(Row, Exported)));
        Observer.ObserveError('export of an empty field');
        Observer.Observe('exported length', Format(Exported.Length()));
        Observer.Expect('export ok', 'Yes');
        Observer.Expect('export of an empty field|text', '');
        Observer.Expect('export of an empty field|code', '');
        Observer.Expect('exported length', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryItem(var Row: Record "W7 Media Row"; Index: Integer; var Id: Guid)
    begin
        Id := Row.Pics.Item(Index);
    end;

    [Test]
    procedure MediaSet_ImportStreamItemsAndOutOfRangeItem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 Media Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        First: Guid;
        Second: Guid;
        Id: Guid;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        PngStream(TempBlob, InS);
        First := Row.Pics.ImportStream(InS, 'one');
        Observer.Observe('first import: returned = MediaId()', Format(First = Row.Pics.MediaId()));
        Clear(TempBlob);
        PngStream(TempBlob, InS);
        Second := Row.Pics.ImportStream(InS, 'two');
        Observer.Observe('second import: returned = MediaId()', Format(Second = Row.Pics.MediaId()));
        Observer.Observe('second import: the set id is unchanged', Format(First = Second));
        Row.Insert();
        Observer.Observe('Count', Format(Row.Pics.Count()));
        Observer.Observe('Item(1) is not null', Format(not IsNullGuid(Row.Pics.Item(1))));
        Observer.Observe('Item(2) is not null', Format(not IsNullGuid(Row.Pics.Item(2))));
        Observer.Observe('Item(1) = Item(2)', Format(Row.Pics.Item(1) = Row.Pics.Item(2)));
        Observer.Observe('item 3 ok', Format(TryItem(Row, 3, Id)));
        Observer.ObserveError('item 3');
        Observer.Observe('item 0 ok', Format(TryItem(Row, 0, Id)));
        Observer.ObserveError('item 0');
        Observer.Expect('first import: returned = MediaId()', 'Yes');
        Observer.Expect('second import: returned = MediaId()', 'Yes');
        Observer.Expect('second import: the set id is unchanged', 'Yes');
        Observer.Expect('Count', '2');
        Observer.Expect('Item(1) is not null', 'Yes');
        Observer.Expect('Item(2) is not null', 'Yes');
        Observer.Expect('Item(1) = Item(2)', 'No');
        Observer.Expect('item 3 ok', 'No');
        Observer.Expect('item 3|text', 'Argument was out of range: index.');
        Observer.Expect('item 3|code', 'ArgumentOutOfRange');
        Observer.Expect('item 0 ok', 'No');
        Observer.Expect('item 0|text', 'The parameter index must have a value greater than zero.');
        Observer.Expect('item 0|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;
}
