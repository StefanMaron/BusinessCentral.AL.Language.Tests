// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74799
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: the columns of the Base Application table Custom Report Layout (9650) through RecordRef/FieldRef: number, name, type, length and field class of each column, and
//   whether the first row (if any) can be read column by column with Format(FieldRef.Value) for every non-BLOB column (read only, no values asserted: the rows of the
//   table depend on the database). Extension Logo: the symbols of BC 27 hold no table of that name (Extension Logo Part is a page), so there is nothing to read.
//   Report Metadata and Windows Language are pinned in metadata/lt-report-metadata-columns and record/TestWindowsLanguageTable.al.
// BC versions: all (CI)

codeunit 74799 "LT CRL Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Columns_Schema()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
    begin
        RR.Open(Database::"Custom Report Layout");
        Observer.Observe('fieldCount', Format(RR.FieldCount()));
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Observer.Observe('f' + Format(FR.Number()), FR.Name() + ':' + Format(FR.Type()) + ':' + Format(FR.Length()) + ':' + Format(FR.Class()));
        end;
        Observer.Observe('primaryKey', Format(RR.KeyCount() > 0));
        Observer.Finish();
    end;

    [Test]
    procedure Columns_ReadFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Readable: Integer;
        Skipped: Integer;
        Value: Text;
    begin
        RR.Open(Database::"Custom Report Layout");
        if not RR.FindFirst() then begin
            Observer.Observe('hasRow', 'false');
            Observer.Finish();
            exit;
        end;
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Type() = FieldType::BLOB then
                Skipped += 1
            else begin
                Value := Format(FR.Value());
                Readable += 1;
            end;
        end;
        Observer.Observe('readable', Format(Readable));
        Observer.Observe('blobSkipped', Format(Skipped));
        Observer.Finish();
    end;
}
