// Batch 7 probes: Format(Record) with a FlowFilter field, an unloaded Blob and a copied record. Observe only.
table 68566 "W7 FR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Amount; Decimal) { }
        field(4; Flt; Code[10]) { FieldClass = FlowFilter; }
        field(5; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("W7 FR Line".Amount where("Row Id" = field(Id), Tag = field(Flt)));
        }
        field(6; Pic; Blob) { }
        field(7; Dt; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68567 "W7 FR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Row Id"; Integer) { }
        field(3; Tag; Code[10]) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

codeunit 68568 "W7 Format Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithBlob: Boolean)
    var
        Row: Record "W7 FR Row";
        Line: Record "W7 FR Line";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        Row.Id := 1;
        Row.Txt := 'abc';
        Row.Amount := 2.5;
        Row.Dt := DMY2Date(5, 3, 2024);
        if WithBlob then begin
            Row.Pic.CreateOutStream(OutS);
            OutS.WriteText('blob bytes');
        end;
        Row.Insert();
        Line.Init();
        Line."Line No." := 1;
        Line."Row Id" := 1;
        Line.Tag := 'A';
        Line.Amount := 10;
        Line.Insert();
        Line."Line No." := 2;
        Line.Tag := 'B';
        Line.Amount := 20;
        Line.Insert();
    end;

    [Test]
    procedure FormatRecord_FlowFilterField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 FR Row";
    begin
        Seed(false);
        Row.Get(1);
        Observer.Observe('no flow filter', Format(Row));
        Row.SetRange(Flt, 'A');
        Observer.Observe('flow filter A', Format(Row));
        Row.CalcFields(Total);
        Observer.Observe('flow filter A, Total calculated', Format(Row));
        Observer.Observe('Total', Format(Row.Total));
        Row.SetFilter(Flt, 'A|B');
        Row.CalcFields(Total);
        Observer.Observe('flow filter A|B, Total calculated', Format(Row));
        Row.SetRange(Flt);
        Observer.Observe('flow filter cleared', Format(Row));
        Row.Flt := 'X';
        Observer.Observe('field Flt assigned X', Format(Row));
        Observer.Observe('Flt read', Row.Flt);
        Observer.Observe('Flt as text of the field', Format(Row.Flt));
        Observer.Expect('no flow filter', '1\tabc\t2.5\t \t03/05/24\t\t0');
        Observer.Expect('flow filter A', '1\tabc\t2.5\t \t03/05/24\t\t0');
        Observer.Expect('flow filter A, Total calculated', '1\tabc\t2.5\t \t03/05/24\t\t10');
        Observer.Expect('Total', '10');
        Observer.Expect('flow filter A|B, Total calculated', '1\tabc\t2.5\t \t03/05/24\t\t30');
        Observer.Expect('flow filter cleared', '1\tabc\t2.5\t \t03/05/24\t\t30');
        Observer.Expect('field Flt assigned X', '1\tabc\t2.5\t \t03/05/24\tX\t30');
        Observer.Expect('Flt read', 'X');
        Observer.Expect('Flt as text of the field', 'X');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRecord_BlobNotLoaded_Loaded_AndEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 FR Row";
    begin
        Seed(true);
        Row.Get(1);
        Observer.Observe('after Get, blob not loaded', Format(Row));
        Row.CalcFields(Pic);
        Observer.Observe('after CalcFields', Format(Row));
        Seed(false);
        Row.Get(1);
        Observer.Observe('empty blob after Get', Format(Row));
        Row.CalcFields(Pic);
        Observer.Observe('empty blob after CalcFields', Format(Row));
        Seed(true);
        Row.SetAutoCalcFields(Pic);
        Row.Get(1);
        Observer.Observe('autocalc blob after Get', Format(Row));
        Seed(true);
        Clear(Row);
        Row.FindFirst();
        Observer.Observe('after FindFirst, blob not loaded', Format(Row));
        Observer.Expect('after Get, blob not loaded', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('after CalcFields', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('empty blob after Get', '1\tabc\t2.5\t \t03/05/24\t\t0');
        Observer.Expect('empty blob after CalcFields', '1\tabc\t2.5\t \t03/05/24\t\t0');
        Observer.Expect('autocalc blob after Get', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('after FindFirst, blob not loaded', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRecord_CopyOfARecordWithABlob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 FR Row";
        Copy: Record "W7 FR Row";
        InS: InStream;
        Text: Text;
    begin
        Seed(true);
        Row.Get(1);
        Row.CalcFields(Pic);
        Copy := Row;
        Observer.Observe('copy', Format(Copy));
        Clear(Row.Pic);
        Observer.Observe('original after Clear of its blob', Format(Row));
        Observer.Observe('copy after that', Format(Copy));
        Copy.CalcFields(Pic);
        Copy.Pic.CreateInStream(InS);
        InS.ReadText(Text);
        Observer.Observe('copy blob text', Text);

        Seed(true);
        Row.Get(1);
        Copy := Row;
        Observer.Observe('copy made before the blob was loaded', Format(Copy));
        Copy.CalcFields(Pic);
        Observer.Observe('copy after CalcFields', Format(Copy));
        Copy.Pic.CreateInStream(InS);
        InS.ReadText(Text);
        Observer.Observe('copy blob text', Text);
        Observer.Expect('copy', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('original after Clear of its blob', '1\tabc\t2.5\t \t03/05/24\t\t0');
        Observer.Expect('copy after that', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('copy blob text', 'blob bytes');
        Observer.Expect('copy made before the blob was loaded', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('copy after CalcFields', '1\tabc\t2.5\t*\t03/05/24\t\t0');
        Observer.Expect('copy blob text', 'blob bytes');
        Observer.Verify();
    end;
}
