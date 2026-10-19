// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Probe (writer BW): AL across three or four apps, with the cross-app fixtures A, B and C (CONTRIBUTING.md, "Multi-app fixtures").
//   #668 item 87 (cross-app half): a table extension of app B declares a procedure with the name and signature of a procedure of app A's
//     table (compiler warning AL0523 "... already defines a method called ... This warning will become an error in a future release."),
//     and one whose name differs only in case. A call from this third app does not compile: AL0196 "The call is ambiguous between the
//     method 'BwSame()' defined in Table ... and the method 'BwSame()' defined in TableExtension ..." (must-not-compile 1581). Which body
//     runs when app A or app B calls it?
//   #668 item 95: app B's page has a protected variable whose type is a table of the AL Internals Test Fixture app; app C depends only on A
//     and B and extends the page. The publish works and the extension runs (microsoft/AL issue 6637 said the publish failed before
//     runtime 27.0). Using the variable from app C does not compile: AL0132 '__MissingTypeSymbol__' (must-not-compile 1580).
//   #668 item 96: Rename of a record of app A's table whose only extension field (app B) is a Blob, compared with a Text extension field.
//   #668 item 102: this app's page (SourceTableView) and FlowField (CalcFormula) filter on an Option field that app B's extension adds.
//   #664 item 14: this app's table extension reads and writes a field that app B's extension of the same table adds.
//   #664 item 144: app B subscribes to a local integration event of app A (compiles with no diagnostic).
// Fixtures: BwCrossAppObjects.al, tests/al-language-xapp-a|b|c. Probe Observer (69160).
// BC versions: 27 - 29

codeunit 83951 "LT BW Cross App Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure TableExt_SameProcedureNameInAnotherApp_WhichBodyRuns()
    var
        Base: Record "LT BW XA Base";
    begin
        Initialize();
        Observer.Observe('BwSame from app A', Base.BwCallSameFromA());
        Observer.Observe('BwSame from app B', Base.BwCallSameFromB());
        Observer.Observe('BwOverload Integer', Base.BwOverload(5));
        Observer.Observe('BwOverload Text', Base.BwOverload('x'));
        Observer.Finish();
    end;

    [Test]
    procedure Page_SourceTableViewAndFlowField_OnFieldOfAnotherAppsExtension()
    var
        Base: Record "LT BW XA Base";
        Counts: Record "LT BW XApp Counts";
        List: TestPage "LT BW XApp Second Kind List";
        Seen: Text;
    begin
        Initialize();
        AddBase('K1', Base."BW XB Kind"::First, 'n1');
        AddBase('K2', Base."BW XB Kind"::Second, 'n2');
        AddBase('K3', Base."BW XB Kind"::Second, 'n2');
        AddBase('K4', Base."BW XB Kind"::Third, 'n1');
        List.OpenView();
        if List.First() then
            repeat
                Seen += List."No.".Value() + ';';
            until not List.Next();
        List.Close();
        Observer.Observe('page rows', Seen);
        Counts."No." := 'C';
        Counts.Insert();
        Counts.CalcFields("Second Kind Count");
        Observer.Observe('flowfield count Second', Format(Counts."Second Kind Count"));
        Counts.SetRange("Note Filter", 'n1');
        Counts.CalcFields("Note Filter Count");
        Observer.Observe('flowfield count note n1', Format(Counts."Note Filter Count"));
        Base.SetRange("BW XB Kind", Base."BW XB Kind"::Second);
        Observer.Observe('SetRange count Second', Format(Base.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Rename_BlobOnlyExtensionOfAnotherApp_BlobAndOldKey()
    var
        Row: Record "LT BW XA Rename Blob";
        Fresh: Record "LT BW XA Rename Blob";
        OutS: OutStream;
    begin
        Initialize();
        Row."No." := 'OLD';
        Row.Description := 'old row';
        Row."BW XB Blob".CreateOutStream(OutS);
        OutS.WriteText('blob of OLD');
        Row.Insert();
        Row.Rename('NEW');
        Observer.Observe('blob in variable after rename', BlobText(Row));
        Observer.Observe('get NEW', Format(Fresh.Get('NEW')));
        Fresh.CalcFields("BW XB Blob");
        Observer.Observe('NEW has value', Format(Fresh."BW XB Blob".HasValue()));
        Observer.Observe('NEW blob', BlobText(Fresh));
        Clear(Fresh);
        Observer.Observe('get OLD', Format(Fresh.Get('OLD')));
        Clear(Fresh);
        Fresh."No." := 'OLD';
        Fresh.Description := 'second old row';
        Observer.Observe('insert OLD again', Format(Fresh.Insert()));
        Clear(Fresh);
        Fresh.Get('OLD');
        Fresh.CalcFields("BW XB Blob");
        Observer.Observe('new OLD has value', Format(Fresh."BW XB Blob".HasValue()));
        Observer.Observe('new OLD blob', BlobText(Fresh));
        Observer.Observe('rows', Format(Fresh.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Rename_TextOnlyExtensionOfAnotherApp_FieldAndOldKey()
    var
        Row: Record "LT BW XA Rename Text";
        Fresh: Record "LT BW XA Rename Text";
    begin
        Initialize();
        Row."No." := 'OLD';
        Row."BW XB Text" := 'text of OLD';
        Row.Insert();
        Row.Rename('NEW');
        Observer.Observe('get NEW', Format(Fresh.Get('NEW')));
        Observer.Observe('NEW text', Fresh."BW XB Text");
        Clear(Fresh);
        Observer.Observe('get OLD', Format(Fresh.Get('OLD')));
        Clear(Fresh);
        Fresh."No." := 'OLD';
        Observer.Observe('insert OLD again', Format(Fresh.Insert()));
        Clear(Fresh);
        Fresh.Get('OLD');
        Observer.Observe('new OLD text', Fresh."BW XB Text");
        Observer.Observe('rows', Format(Fresh.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageExt_ProtectedVarTypeFromUnreferencedApp_ExtensionRuns()
    var
        Master: Record "LT BW XB Master";
        Card: TestPage "LT BW XB Master Card";
    begin
        Initialize();
        Master."No." := 'M1';
        Master.Insert();
        Card.OpenView();
        Card.GoToRecord(Master);
        Observer.Observe('No.', Card."No.".Value());
        Observer.Observe('C marker', Card.BwXcMarker.Value());
        Observer.Observe('blah filter', Card.BlahFilterText.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure LocalEvent_SubscriberInDependentApp_Runs()
    var
        Publisher: Codeunit "LT BW XA Local Publisher";
    begin
        Initialize();
        Observer.Observe('log', Publisher.Raise());
        Observer.Finish();
    end;

    [Test]
    procedure TableExt_FieldOfAnotherAppsExtension_ReadAndWrite()
    var
        Base: Record "LT BW XA Base";
        Fresh: Record "LT BW XA Base";
    begin
        Initialize();
        Base."No." := 'F1';
        Base."BW XB Note" := 'note of B';
        Base.Insert();
        Observer.Observe('copy', Base.BwCopyNote());
        Base.Validate("BW M Copy", 'abc');
        Base.Modify();
        Fresh.Get('F1');
        Observer.Observe('B note after validate in M', Fresh."BW XB Note");
        Observer.Observe('M copy', Fresh."BW M Copy");
        Observer.Finish();
    end;

    local procedure AddBase(No: Code[20]; Kind: Integer; Note: Text[30])
    var
        Base: Record "LT BW XA Base";
    begin
        Base."No." := No;
        Base."BW XB Kind" := Kind;
        Base."BW XB Note" := Note;
        Base.Insert();
    end;

    local procedure BlobText(var Row: Record "LT BW XA Rename Blob"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        if not Row."BW XB Blob".HasValue() then
            exit('<none>');
        Row."BW XB Blob".CreateInStream(InS);
        InS.ReadText(Result);
        exit(Result);
    end;

    local procedure Initialize()
    var
        Base: Record "LT BW XA Base";
        RenameBlob: Record "LT BW XA Rename Blob";
        RenameText: Record "LT BW XA Rename Text";
        Counts: Record "LT BW XApp Counts";
        Master: Record "LT BW XB Master";
    begin
        Base.DeleteAll();
        RenameBlob.DeleteAll();
        RenameText.DeleteAll();
        Counts.DeleteAll();
        Master.DeleteAll();
    end;
}
