// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 79005 (declared in types/lt-aj-probes/AjMisc.al), codeunits 79003 79004 79020, xmlports 79008 79009 79010
// Facts: this.Run() inside a codeunit (with OnRun code, with an empty OnRun, with an OnRun that raises an error, with a record parameter); what an XmlPort import leaves in a table element's temporary table and in the real table for UseTemporary = true with AutoSave = false, UseTemporary = true with AutoSave left on, and AutoSave = false without UseTemporary.
// BC versions: 27.5+

codeunit 79003 "LT AJ Run Plain"
{
    var
        RunCount: Integer;

    trigger OnRun()
    begin
        RunCount += 1;
    end;

    procedure CallThisRun(): Boolean
    begin
        exit(this.Run());
    end;

    procedure CallThisRunAsStatement()
    begin
        this.Run();
    end;

    procedure GetCount(): Integer
    begin
        exit(RunCount);
    end;
}

codeunit 79004 "LT AJ Run Empty"
{
    trigger OnRun()
    begin
    end;

    procedure CallThisRun(): Boolean
    begin
        exit(this.Run());
    end;
}

codeunit 79021 "LT AJ Run Error"
{
    trigger OnRun()
    begin
        Error('boom from OnRun');
    end;

    procedure CallThisRun(): Boolean
    begin
        exit(this.Run());
    end;

    procedure CallThisRunAsStatement()
    begin
        this.Run();
    end;
}

codeunit 79020 "LT AJ Run Rec"
{
    TableNo = "LT AJ Item";

    var
        RunCount: Integer;

    trigger OnRun()
    begin
        RunCount += 1;
        Rec.Txt := 'ran ' + Format(RunCount);
        Rec.Id += 100;
    end;

    procedure CallThisRun(var R: Record "LT AJ Item"): Boolean
    begin
        exit(this.Run(R));
    end;

    procedure GetCount(): Integer
    begin
        exit(RunCount);
    end;
}

codeunit 79002 "LT AJ This Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ThisRun_WithOnRunCode()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "LT AJ Run Plain";
        Ok: Boolean;
    begin
        Ok := Plain.CallThisRun();
        Observer.Observe('first call', Format(Ok) + '|' + Format(Plain.GetCount()));
        Ok := Plain.CallThisRun();
        Observer.Observe('second call', Format(Ok) + '|' + Format(Plain.GetCount()));
        Plain.CallThisRunAsStatement();
        Observer.Observe('statement', Format(Plain.GetCount()));
        Ok := Plain.Run();
        Observer.Observe('outside Run', Format(Ok) + '|' + Format(Plain.GetCount()));
        Observer.Expect('first call', 'Yes|1');
        Observer.Expect('second call', 'Yes|2');
        Observer.Expect('statement', '3');
        Observer.Expect('outside Run', 'Yes|4');
        Observer.Verify();
    end;

    [Test]
    procedure ThisRun_EmptyOnRun()
    var
        Observer: Codeunit "Probe Observer";
        Empty: Codeunit "LT AJ Run Empty";
        Ok: Boolean;
    begin
        Ok := Empty.CallThisRun();
        Observer.Observe('empty OnRun', Format(Ok));
        Observer.Expect('empty OnRun', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ThisRun_OnRunRaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Failing: Codeunit "LT AJ Run Error";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Failing.CallThisRun();
        Observer.Observe('error returned', Format(Ok));
        Observer.ObserveError('error returned');
        asserterror Failing.CallThisRunAsStatement();
        Observer.ObserveError('error statement');
        Observer.Expect('error returned', 'No');
        Observer.Expect('error returned|text', 'boom from OnRun');
        Observer.Expect('error returned|code', 'Dialog');
        Observer.Expect('error statement|text', 'boom from OnRun');
        Observer.Expect('error statement|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ThisRun_WithRecordParameter()
    var
        Observer: Codeunit "Probe Observer";
        WithRec: Codeunit "LT AJ Run Rec";
        Item: Record "LT AJ Item";
        Ok: Boolean;
    begin
        Item.Id := 1;
        Item.Txt := 'before';
        Ok := WithRec.CallThisRun(Item);
        Observer.Observe('first', Format(Ok) + '|' + Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        Ok := WithRec.CallThisRun(Item);
        Observer.Observe('second', Format(Ok) + '|' + Format(Item.Id) + '|' + Item.Txt + '|' + Format(WithRec.GetCount()));
        Observer.Expect('first', 'Yes|101|ran 1|1');
        Observer.Expect('second', 'Yes|201|ran 2|2');
        Observer.Verify();
    end;
}

xmlport 79008 "LT AJ Xp Temp No Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                UseTemporary = true;
                AutoSave = false;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log += 'afterInsert temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ' isTemp=' + Format(Item.IsTemporary()) + ';';
                end;
            }
        }
    }

    var
        Real: Record "LT AJ Item";
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 79009 "LT AJ Xp Temp Auto Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                UseTemporary = true;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log += 'afterInsert temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
                end;
            }
        }
    }

    var
        Real: Record "LT AJ Item";
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post temp=' + Format(Item.Count()) + ' real=' + Format(Real.Count()) + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

xmlport 79010 "LT AJ Xp Real No Save"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Item; "LT AJ Item")
            {
                AutoSave = false;
                XmlName = 'Row';

                fieldelement(Id; Item.Id) { }
                fieldelement(Txt; Item.Txt) { }

                trigger OnAfterInsertRecord()
                begin
                    Log += 'afterInsert count=' + Format(Item.Count()) + ';';
                end;
            }
        }
    }

    var
        Log: Text;

    trigger OnPostXmlPort()
    begin
        Log += 'post count=' + Format(Item.Count()) + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;
}

codeunit 79011 "LT AJ XmlPort Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Source(var Tmp: Codeunit "Temp Blob"; var Ins: InStream)
    var
        Outs: OutStream;
    begin
        Tmp.CreateOutStream(Outs);
        Outs.WriteText('<Root><Row><Id>1</Id><Txt>one</Txt></Row><Row><Id>2</Id><Txt>two</Txt></Row></Root>');
        Tmp.CreateInStream(Ins);
    end;

    [Test]
    procedure XmlPort_UseTemporary_AutoSaveFalse_Import()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT AJ Xp Temp No Save";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'afterInsert temp=0 real=0 isTemp=Yes;afterInsert temp=0 real=0 isTemp=Yes;post temp=0 real=0;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_UseTemporary_AutoSaveDefault_Import()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT AJ Xp Temp Auto Save";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'afterInsert temp=1 real=0;afterInsert temp=2 real=0;post temp=2 real=0;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_RealTable_AutoSaveFalse_Import()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Codeunit "Temp Blob";
        Ins: InStream;
        Xp: XmlPort "LT AJ Xp Real No Save";
        Real: Record "LT AJ Item";
    begin
        Real.DeleteAll();
        Source(Tmp, Ins);
        Xp.SetSource(Ins);
        Xp.Import();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('real after', Format(Real.Count()));
        Observer.Expect('log', 'afterInsert count=0;afterInsert count=0;post count=0;');
        Observer.Expect('real after', '0');
        Observer.Verify();
    end;
}
