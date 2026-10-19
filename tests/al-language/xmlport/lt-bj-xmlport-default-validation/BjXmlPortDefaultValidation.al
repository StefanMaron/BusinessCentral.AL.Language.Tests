// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-defaultfieldsvalidation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 81670 and 81671, log codeunit 81672, xmlports 81673 to 81675, test codeunit 81676
// Probe: corpus issue 601 item 14. XmlPort DefaultFieldsValidation = true (set explicitly), = false and not set, on an import: which OnValidate
//   triggers run for a field element without FieldValidate, with FieldValidate = Yes and with FieldValidate = No, in which order, and what a
//   value that is not in the related table does under each setting.
// BC versions: 27, 28, 29

table 81670 "LT BJ Xv Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 81671 "LT BJ Xv Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Text[20])
        {
            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Plain=' + Plain + ' xRec=' + xRec.Plain);
            end;
        }
        field(3; Forced; Text[20])
        {
            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Forced=' + Forced);
            end;
        }
        field(4; Skipped; Text[20])
        {
            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Skipped=' + Skipped);
            end;
        }
        field(5; Rel; Code[10])
        {
            TableRelation = "LT BJ Xv Rel".Code;

            trigger OnValidate()
            var
                XvLog: Codeunit "LT BJ Xv Log";
            begin
                XvLog.Add('val Rel=' + Rel);
            end;
        }
        field(6; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        XvLog: Codeunit "LT BJ Xv Log";
    begin
        XvLog.Add('insert ' + Format(Id));
    end;
}

codeunit 81672 "LT BJ Xv Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

xmlport 81673 "LT BJ Xv True"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = true;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT BJ Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(Plain; Row.Plain) { MinOccurs = Zero; }
                fieldelement(Forced; Row.Forced) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Skipped; Row.Skipped) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 81674 "LT BJ Xv False"
{
    Direction = Import;
    Format = Xml;
    DefaultFieldsValidation = false;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT BJ Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(Plain; Row.Plain) { MinOccurs = Zero; }
                fieldelement(Forced; Row.Forced) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Skipped; Row.Skipped) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 81675 "LT BJ Xv Unset"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT BJ Xv Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldelement(Plain; Row.Plain) { MinOccurs = Zero; }
                fieldelement(Forced; Row.Forced) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Skipped; Row.Skipped) { MinOccurs = Zero; FieldValidate = No; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; }
            }
        }
    }
}

codeunit 81676 "LT BJ Xv Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        XvLog: Codeunit "LT BJ Xv Log";
        OrderXml: Label '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="1"><Plain>p1</Plain><Forced>f1</Forced><Skipped>s1</Skipped><Rel>R1</Rel></Row><Row Id="2"><Skipped>s2</Skipped><Plain>p2</Plain></Row></Root>', Locked = true;
        GoodXml: Label '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="1"><Plain>p1</Plain><Forced>f1</Forced><Skipped>s1</Skipped><Rel>R1</Rel></Row><Row Id="2"><Plain>p2</Plain><Skipped>s2</Skipped></Row></Root>', Locked = true;
        BadRelXml: Label '<?xml version="1.0" encoding="utf-8"?><Root><Row Id="3"><Plain>p3</Plain><Rel>NOPE</Rel></Row></Root>', Locked = true;

    local procedure Seed()
    var
        Row: Record "LT BJ Xv Row";
        Rel: Record "LT BJ Xv Rel";
    begin
        Row.DeleteAll();
        Rel.DeleteAll();
        Rel.Code := 'R1';
        Rel.Insert();
        XvLog.Take();
    end;

    [TryFunction]
    local procedure TryImport(XmlPortId: Integer; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(XmlPortId, InS);
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT BJ Xv Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Plain + ':' + Row.Forced + ':' + Row.Skipped + ':' + Row.Rel + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Probe(Tag: Text; XmlPortId: Integer)
    begin
        Seed();
        ClearLastError();
        Observer.Observe(Tag + ' order ok', Format(TryImport(XmlPortId, OrderXml)));
        Observer.Observe(Tag + ' order error', GetLastErrorText());
        Observer.Observe(Tag + ' order log', XvLog.Take());
        Observer.Observe(Tag + ' order rows', Rows());
        Seed();
        ClearLastError();
        if TryImport(XmlPortId, BadRelXml) then
            Observer.Observe(Tag + ' bad rel', 'ok')
        else
            Observer.ObserveError(Tag + ' bad rel');
        Observer.Observe(Tag + ' bad rel log', XvLog.Take());
        Observer.Observe(Tag + ' bad rel rows', Rows());
    end;

    local procedure ProbeInOrder(Tag: Text; XmlPortId: Integer)
    begin
        Seed();
        ClearLastError();
        Observer.Observe(Tag + ' good ok', Format(TryImport(XmlPortId, GoodXml)));
        Observer.Observe(Tag + ' good error', GetLastErrorText());
        Observer.Observe(Tag + ' good log', XvLog.Take());
        Observer.Observe(Tag + ' good rows', Rows());
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_True()
    begin
        Probe('true', Xmlport::"LT BJ Xv True");
        Observer.Expect('true order ok', 'No');
        Observer.Expect('true order error', 'Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Plain''. List of possible elements expected: ''Rel''.');
        Observer.Expect('true order log', 'val Plain=p1 xRec=p1;val Forced=f1;val Rel=R1;insert 1;');
        Observer.Expect('true order rows', '1:p1:f1:s1:R1,');
        Observer.Expect('true bad rel|text', 'The field Rel of table LT BJ Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel).');
        Observer.Expect('true bad rel|code', 'DB:PrimRecordNotFound');
        Observer.Expect('true bad rel log', 'val Plain=p3 xRec=p3;');
        Observer.Expect('true bad rel rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_False()
    begin
        Probe('false', Xmlport::"LT BJ Xv False");
        Observer.Expect('false order ok', 'No');
        Observer.Expect('false order error', 'Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Plain''. List of possible elements expected: ''Rel''.');
        Observer.Expect('false order log', 'val Forced=f1;insert 1;');
        Observer.Expect('false order rows', '1:p1:f1:s1:R1,');
        Observer.Expect('false bad rel', 'ok');
        Observer.Expect('false bad rel log', 'insert 3;');
        Observer.Expect('false bad rel rows', '3:p3:::NOPE,');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_Unset()
    begin
        Probe('unset', Xmlport::"LT BJ Xv Unset");
        Observer.Expect('unset order ok', 'No');
        Observer.Expect('unset order error', 'Imported XML cannot validate with the schema: The element ''Row'' has invalid child element ''Plain''. List of possible elements expected: ''Rel''.');
        Observer.Expect('unset order log', 'val Plain=p1 xRec=p1;val Forced=f1;val Rel=R1;insert 1;');
        Observer.Expect('unset order rows', '1:p1:f1:s1:R1,');
        Observer.Expect('unset bad rel|text', 'The field Rel of table LT BJ Xv Row contains a value (NOPE) that cannot be found in the related table (LT BJ Xv Rel).');
        Observer.Expect('unset bad rel|code', 'DB:PrimRecordNotFound');
        Observer.Expect('unset bad rel log', 'val Plain=p3 xRec=p3;');
        Observer.Expect('unset bad rel rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_True_InOrder()
    begin
        ProbeInOrder('true', Xmlport::"LT BJ Xv True");
        Observer.Finish();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_False_InOrder()
    begin
        ProbeInOrder('false', Xmlport::"LT BJ Xv False");
        Observer.Finish();
    end;

    [Test]
    procedure XmlPort_DefaultFieldsValidation_Unset_InOrder()
    begin
        ProbeInOrder('unset', Xmlport::"LT BJ Xv Unset");
        Observer.Finish();
    end;
}
