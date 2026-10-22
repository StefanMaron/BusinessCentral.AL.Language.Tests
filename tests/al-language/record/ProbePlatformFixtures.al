// Fixtures for the platform-table probes: a row dumper (every non-system column of the current row as no=name=value)
// and objects whose declared properties the metadata tables should report.
codeunit 69468 "Probe Row Dumper"
{
    procedure Dump(var RecRef: RecordRef): Text
    var
        FRef: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FRef := RecRef.FieldIndex(i);
            Result += Format(FRef.Number()) + ':' + FRef.Name() + '=';
            if FRef.Type() in [FieldType::BLOB, FieldType::Media, FieldType::MediaSet] then
                Result += '(binary)'
            else
                Result += Format(FRef.Value());
            Result += ' | ';
        end;
        exit(Result);
    end;

    procedure DumpAll(var RecRef: RecordRef; MaxRows: Integer): Text
    var
        Result: Text;
        n: Integer;
    begin
        if RecRef.FindSet() then
            repeat
                n += 1;
                Result += '#' + Format(n) + ' ' + Dump(RecRef) + ' ## ';
            until (RecRef.Next() = 0) or (n >= MaxRows);
        if n = 0 then
            exit('(no rows)');
        exit(Result);
    end;
}

table 69469 "Probe Fx Table Defaults"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 69470 "Probe Fx Drill Page"
{
    PageType = List;
    SourceTable = "Probe Fx Table Defaults";
}

table 69471 "Probe Fx Table Props"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;
    PasteIsValid = false;
    CompressionType = Page;
    DrillDownPageId = "Probe Fx Drill Page";
    LookupPageId = "Probe Fx Drill Page";
    DataPerCompany = false;
    Access = Internal;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69472 "Probe Fx Codeunit Defaults"
{
}

codeunit 69473 "Probe Fx Codeunit Props"
{
    Access = Internal;
    SingleInstance = true;
    TableNo = "Probe Fx Table Defaults";
    Permissions = tabledata "Probe Fx Table Defaults" = r;
}

tableextension 69474 "Probe Fx Table Ext" extends "Probe Fx Table Defaults"
{
    fields
    {
        field(69474; ExtField; Integer) { }
    }
}
