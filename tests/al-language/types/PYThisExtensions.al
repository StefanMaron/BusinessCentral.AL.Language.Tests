// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// Report and page extensions: this.<base procedure>() and this.<extension procedure>() work inside an extension trigger (this.BaseProc, this.ExtProc, this.BasePageProc, this.ExtPageProc).
// this.<extension variable> does NOT compile (AL0847, this is the base object type), this.<non protected base variable> is AL0161 (must-not-compile cases 0121 and 0122). A PROTECTED base
// variable written as this.BaseVar2 compiles in a reportextension but raises at RUN time: "The another object refers to a global variable on ReportExtension with ID <id> that no longer
// seems to exists. Try to recompile dependent extensions." / GlobalVariableNotFound (and for a page extension it aborts the page with the same text).
// A procedure declared in a reportextension (ExtProc, ReadExtra) can be called on a variable of the BASE report; Report.Run on such a variable counts rows in another instance: before and after
// Run the same variable still answers baseproc:0 / items=0 (and a second variable the same). WordMergeDataItem on a report compiles and leaves the SaveAs Xml columns unchanged (the dataset
// of a report with the property equals the dataset of an identical report without it). BindSubscription(this) inside a report does not compile (case 0123).
// Fixtures used: self-contained tables 69343 to 69345, reports 69343 to 69346, report extensions 69343 and 69346, page 69343, page extension 69343, codeunits 69344 and 69345
// BC versions: 27.5, 29.0

report 69343 "PY Base Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "PY Row")
        {
            trigger OnAfterGetRecord()
            begin
                BaseCount += 1;
            end;
        }
    }

    protected var
        BaseCount: Integer;
        BaseVar: Text;

    trigger OnInitReport()
    begin
        BaseVar := 'base';
    end;

    procedure BaseProc(): Text
    begin
        exit('baseproc:' + Format(BaseCount));
    end;
}

reportextension 69343 "PY Report Ext" extends "PY Base Report"
{
    dataset
    {
        addlast(Row)
        {
            dataitem(Extra; "PY Item")
            {
                trigger OnAfterGetRecord()
                begin
                    ExtCount += 1;
                end;
            }
        }
    }

    var
        ExtVar: Text;
        ExtCount: Integer;

    trigger OnPreReport()
    begin
        ExtVar := 'ext';
        ThisLog := 'this.BaseProc=' + this.BaseProc() + ';this.ExtProc=' + this.ExtProc();
    end;

    procedure ExtProc(): Text
    begin
        exit('extproc:' + Format(ExtCount));
    end;

    procedure ReadExtra(): Text
    begin
        exit('items=' + Format(ExtCount) + ';var=' + ExtVar + ';' + ThisLog);
    end;

    var
        ThisLog: Text;
}

report 69344 "PY Plain Report"
{
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Row; "PY Row")
        {
            column(IdCol; Id) { }
        }
    }
}

report 69345 "PY Word Report"
{
    DefaultLayout = RDLC;
    WordMergeDataItem = Row;

    dataset
    {
        dataitem(Row; "PY Row")
        {
            column(IdCol; Id) { }
        }
    }
}

report 69346 "PY Base Report2"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "PY Row") { }
    }

    protected var
        BaseVar2: Text;

    trigger OnInitReport()
    begin
        BaseVar2 := 'base2';
    end;
}

reportextension 69346 "PY Report Ext2" extends "PY Base Report2"
{
    trigger OnPreReport()
    begin
        ThisVarLog := 'this.BaseVar2=' + this.BaseVar2;
    end;

    var
        ThisVarLog: Text;
}

table 69345 "PY Page Row"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69344 "PY This Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 69343 "PY Base Page"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "PY Page Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }

    protected var
        BasePageVar: Text;

    trigger OnOpenPage()
    begin
        BasePageVar := 'basepage';
    end;

    procedure BasePageProc(): Text
    begin
        exit('basepageproc');
    end;
}

pageextension 69343 "PY Page Ext" extends "PY Base Page"
{
    var
        ExtPageVar: Text;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PY This Log";
    begin
        ExtPageVar := 'extpage';
        Log.Add('this.BasePageProc=' + this.BasePageProc() + ';this.ExtPageProc=' + this.ExtPageProc());
    end;

    procedure ExtPageProc(): Text
    begin
        exit('extpageproc');
    end;
}

codeunit 69345 "PY This Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PY Row";
        Item: Record "PY Item";
        PageRow: Record "PY Page Row";
    begin
        Row.DeleteAll();
        Item.DeleteAll();
        PageRow.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Item.Id := 1;
        Item.Insert();
        Item.Id := 2;
        Item.Insert();
        Item.Id := 3;
        Item.Insert();
        PageRow.Id := 1;
        PageRow.Insert();
    end;

    [Test]
    procedure ReportExtension_ThisAndPublicProcedure_BeforeAndAfterRun()
    var
        Base: Report "PY Base Report";
        Ext: Report "PY Base Report";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('before_run_base_proc', Base.BaseProc());
        Observer.Observe('before_run_extension_proc_on_base_variable', Base.ExtProc());
        Observer.Observe('before_run_read_extra', Base.ReadExtra());
        Base.UseRequestPage(false);
        Base.Run();
        Observer.Observe('after_run_base_proc', Base.BaseProc());
        Observer.Observe('after_run_extension_proc', Base.ExtProc());
        Observer.Observe('after_run_read_extra', Base.ReadExtra());
        Observer.Observe('second_variable_base_proc', Ext.BaseProc());
        Observer.Observe('second_variable_read_extra', Ext.ReadExtra());
        Observer.Expect('before_run_base_proc', 'baseproc:0');
        Observer.Expect('before_run_extension_proc_on_base_variable', 'extproc:0');
        Observer.Expect('before_run_read_extra', 'items=0;var=;');
        Observer.Expect('after_run_base_proc', 'baseproc:0');
        Observer.Expect('after_run_extension_proc', 'extproc:0');
        Observer.Expect('after_run_read_extra', 'items=0;var=;');
        Observer.Expect('second_variable_base_proc', 'baseproc:0');
        Observer.Expect('second_variable_read_extra', 'items=0;var=;');
        Observer.Verify();
    end;

    [Test]
    procedure PageExtension_ThisInTrigger()
    var
        Pg: TestPage "PY Base Page";
        Log: Codeunit "PY This Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('log', Log.Take());
        Pg.Close();
        Observer.Expect('log', 'this.BasePageProc=basepageproc;this.ExtPageProc=extpageproc;');
        Observer.Verify();
    end;

    local procedure DatasetColumns(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column ') or Line.StartsWith('<DataItem ') or Line.StartsWith('<DataItems') or Line.StartsWith('<Label ') then
                Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure WordMergeDataItem_SaveAsXml_DatasetUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Text;
        Word: Text;
    begin
        Seed();
        Plain := DatasetColumns(Report::"PY Plain Report");
        Word := DatasetColumns(Report::"PY Word Report");
        Observer.Observe('datasets_equal', Format(Plain = Word));
        Observer.Observe('word_dataset_has_rows', Format(StrPos(Word, 'IdCol') > 0));
        Observer.Expect('datasets_equal', 'Yes');
        Observer.Expect('word_dataset_has_rows', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReportExtension_ThisBaseVariable_ReadInATrigger()
    var
        Rpt: Report "PY Base Report2";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rpt.UseRequestPage(false);
        asserterror Rpt.Run();
        Observer.ObserveError('this_base_variable');
        Observer.Expect('this_base_variable|text', 'The another object refers to a global variable on ReportExtension with ID 69346 that no longer seems to exists. Try to recompile dependent extensions.');
        Observer.Expect('this_base_variable|code', 'GlobalVariableNotFound');
        Observer.Verify();
    end;
}
