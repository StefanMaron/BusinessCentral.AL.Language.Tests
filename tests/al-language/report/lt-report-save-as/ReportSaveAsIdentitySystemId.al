// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); layout file ./ProbeSaveAsDatasetLayout.rdl of the app root (only named, SaveAs Xml does not render it)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73763 "LT P165 SaveAs Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73764 "LT P165 SaveAs Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 73765 "LT P165 SaveAs Identity"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(P; "LT P165 SaveAs Parent")
        {
            column(PNo; Id) { }
            column(PName; Name) { }

            dataitem(C; "LT P165 SaveAs Child")
            {
                DataItemLink = ParentId = field(Id);

                column(CNo; Id) { }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './ProbeSaveAsDatasetLayout.rdl';
            Caption = 'LT P165 layout';
        }
    }
}

codeunit 73762 "LT P165 SaveAs Identity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT P165 SaveAs Parent";
        Child: Record "LT P165 SaveAs Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'one';
        Parent.Insert();
        Parent.Id := 2;
        Parent.Name := 'two';
        Parent.Insert();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 11;
        Child.ParentId := 2;
        Child.Insert();
        Commit();
    end;

    // the systemId="..." values of the DataItems block, in document order
    local procedure Identities(Parameters: Text; var Ids: List of [Text]; var TableIds: List of [Text])
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Whole: Text;
        P: Integer;
        Q: Integer;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT P165 SaveAs Identity", Parameters, ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Whole += Line + ' ';
        end;
        P := StrPos(Whole, 'tableId="');
        while P > 0 do begin
            Whole := CopyStr(Whole, P + 9);
            Q := StrPos(Whole, '"');
            TableIds.Add(CopyStr(Whole, 1, Q - 1));
            P := StrPos(Whole, 'systemId="');
            Whole := CopyStr(Whole, P + 10);
            Q := StrPos(Whole, '"');
            Ids.Add(CopyStr(Whole, 1, Q - 1));
            P := StrPos(Whole, 'tableId="');
        end;
    end;

    local procedure Plain(Value: Guid): Text
    begin
        exit(LowerCase(DelChr(Format(Value), '=', '{}')));
    end;

    [Test]
    procedure SaveAs_DataItemSystemIds_AreTheRowSystemIds()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT P165 SaveAs Parent";
        Child: Record "LT P165 SaveAs Child";
        Ids: List of [Text];
        TableIds: List of [Text];
    begin
        Seed();
        Identities('', Ids, TableIds);
        Observer.Observe('pairs', Format(Ids.Count()));
        if Ids.Count() >= 4 then begin
            Parent.Get(1);
            Observer.Observe('p1 equals row SystemId', Format(Ids.Get(1) = Plain(Parent.SystemId)));
            Child.Get(10);
            Observer.Observe('c10 equals row SystemId', Format(Ids.Get(2) = Plain(Child.SystemId)));
            Child.Get(11);
            Observer.Observe('c11 equals row SystemId', Format(Ids.Get(4) = Plain(Child.SystemId)));
            Parent.Get(2);
            Observer.Observe('p2 equals row SystemId', Format(Ids.Get(3) = Plain(Parent.SystemId)));
            Observer.Observe('table ids', TableIds.Get(1) + ';' + TableIds.Get(2) + ';' + TableIds.Get(3) + ';' + TableIds.Get(4));
        end;
        Observer.Expect('pairs', '4');
        Observer.Expect('p1 equals row SystemId', 'Yes');
        Observer.Expect('c10 equals row SystemId', 'Yes');
        Observer.Expect('c11 equals row SystemId', 'Yes');
        Observer.Expect('p2 equals row SystemId', 'Yes');
        Observer.Expect('table ids', '73763;73764;73763;73764');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_DataItemSystemId_FollowsAnAssignedSystemId()
    var
        Observer: Codeunit "Probe Observer";
        Parent: Record "LT P165 SaveAs Parent";
        Own: Guid;
        Ids: List of [Text];
        TableIds: List of [Text];
    begin
        Seed();
        Parent.DeleteAll();
        Own := CreateGuid();
        Parent.Id := 5;
        Parent.SystemId := Own;
        Parent.Insert(false, true);
        Commit();
        Identities('', Ids, TableIds);
        Observer.Observe('pairs', Format(Ids.Count()));
        if Ids.Count() >= 1 then
            Observer.Observe('assigned equals', Format(Ids.Get(1) = Plain(Own)));
        Observer.Expect('pairs', '1');
        Observer.Expect('assigned equals', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_DataItemSystemId_AfterAFilterAndARunAgain()
    var
        Observer: Codeunit "Probe Observer";
        FirstRun: List of [Text];
        SecondRun: List of [Text];
        TableIds: List of [Text];
    begin
        Seed();
        Identities('', FirstRun, TableIds);
        Clear(TableIds);
        Identities('', SecondRun, TableIds);
        Observer.Observe('count first', Format(FirstRun.Count()));
        Observer.Observe('count second', Format(SecondRun.Count()));
        if (FirstRun.Count() > 0) and (SecondRun.Count() = FirstRun.Count()) then
            Observer.Observe('same ids on a second run', Format(FirstRun.Get(1) = SecondRun.Get(1)));
        Observer.Expect('count first', '4');
        Observer.Expect('count second', '4');
        Observer.Expect('same ids on a second run', 'Yes');
        Observer.Verify();
    end;
}
