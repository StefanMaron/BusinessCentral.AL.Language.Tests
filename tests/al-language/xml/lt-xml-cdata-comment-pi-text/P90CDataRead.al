// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/XmlCData/xmlcdata-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table LT P90 Blob (table 70729)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlCData AsXmlNode, GetDocument, GetParent, SelectNodes, SelectSingleNode, WriteTo (Text and OutStream), content edge cases, uninitialised variables
// BC versions: 29 (27 and 28 by CI)

codeunit 70731 "LT P90 CData Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlCData;
        U: XmlCData;
        UN: XmlNode;
        Res: Text;
        Lst: XmlNodeList;
        OutS: OutStream;

    local procedure MakeX(Tag: Text): XmlCData
    var
        R: XmlCData;
    begin
        R := XmlCData.Create(Tag);
        exit(R);
    end;

    // Pos: 0 = only child of r, 1 = first, 2 = middle (default), 3 = last child of r (siblings a and b)
    local procedure BuildAt(Attached: Boolean; Pos: Integer; Tag: Text)
    var
        N: XmlNode;
        Fresh: XmlCData;
        Idx: Integer;
    begin
        Fresh := MakeX(Tag);
        if not Attached then begin
            X := Fresh;
            exit;
        end;
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('r');
        if Pos = 0 then
            Root.Add(Fresh)
        else begin
            if Pos = 1 then
                Root.Add(Fresh);
            Root.Add(XmlElement.Create('a'));
            if Pos = 2 then
                Root.Add(Fresh);
            Root.Add(XmlElement.Create('b'));
            if Pos = 3 then
                Root.Add(Fresh);
        end;
        Doc.Add(Root);
        Doc.GetRoot(Root);
        Idx := Pos;
        if Pos = 0 then
            Idx := 1;
        Root.GetChildNodes().Get(Idx, N);
        X := N.AsXmlCData();
    end;

    local procedure Build(Attached: Boolean; Tag: Text)
    begin
        BuildAt(Attached, 2, Tag);
    end;

    local procedure SerDoc(): Text
    var
        S: Text;
    begin
        Doc.WriteTo(S);
        exit(S);
    end;

    local procedure SerX(): Text
    var
        S: Text;
    begin
        X.WriteTo(S);
        exit(S);
    end;

    local procedure SerNode(N: XmlNode): Text
    var
        S: Text;
    begin
        N.WriteTo(S);
        exit(S);
    end;

    // Kinds: 1 element, 2 text, 3 comment, 4 cdata, 5 processing instruction, 6 attribute, 7 declaration, 8 document,
    // 9 document type, 10 sibling element a of X (has a parent), 11 X itself, 12 the root r (ancestor of X),
    // 13 root element of another document, 14 uninitialised XmlNode, 101..103 elements m1..m3
    local procedure MakeArg(Kind: Integer): XmlNode
    var
        E: XmlElement;
        T: XmlText;
        C: XmlComment;
        D: XmlCData;
        P: XmlProcessingInstruction;
        A: XmlAttribute;
        Decl: XmlDeclaration;
        Doc2: XmlDocument;
        DT: XmlDocumentType;
        N: XmlNode;
    begin
        case Kind of
            1:
                begin
                    E := XmlElement.Create('e1');
                    exit(E.AsXmlNode());
                end;
            2:
                begin
                    T := XmlText.Create('t2');
                    exit(T.AsXmlNode());
                end;
            3:
                begin
                    C := XmlComment.Create('c3');
                    exit(C.AsXmlNode());
                end;
            4:
                begin
                    D := XmlCData.Create('d4');
                    exit(D.AsXmlNode());
                end;
            5:
                begin
                    P := XmlProcessingInstruction.Create('p5', 'q5');
                    exit(P.AsXmlNode());
                end;
            6:
                begin
                    A := XmlAttribute.Create('a6', '1');
                    exit(A.AsXmlNode());
                end;
            7:
                begin
                    Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
                    exit(Decl.AsXmlNode());
                end;
            8:
                begin
                    Doc2 := XmlDocument.Create();
                    exit(Doc2.AsXmlNode());
                end;
            9:
                begin
                    DT := XmlDocumentType.Create('dt9');
                    exit(DT.AsXmlNode());
                end;
            10:
                begin
                    Root.SelectSingleNode('a', N);
                    exit(N);
                end;
            11:
                exit(X.AsXmlNode());
            12:
                exit(Root.AsXmlNode());
            13:
                begin
                    Doc2 := XmlDocument.Create();
                    Doc2.Add(XmlElement.Create('f13'));
                    Doc2.GetRoot(E);
                    exit(E.AsXmlNode());
                end;
            14:
                exit(UN);
            101, 102, 103:
                begin
                    E := XmlElement.Create('m' + Format(Kind - 100));
                    exit(E.AsXmlNode());
                end;
        end;
    end;

    [TryFunction]
    local procedure TryAfter(Kind: Integer)
    begin
        X.AddAfterSelf(MakeArg(Kind));
    end;

    [TryFunction]
    local procedure TryBefore(Kind: Integer)
    begin
        X.AddBeforeSelf(MakeArg(Kind));
    end;

    [TryFunction]
    local procedure TryReplace(Kind: Integer)
    begin
        X.ReplaceWith(MakeArg(Kind));
    end;

    [TryFunction]
    local procedure TryRemove()
    begin
        X.Remove();
    end;

    [TryFunction]
    local procedure TryAfter3(A: Integer; B: Integer; C: Integer)
    begin
        X.AddAfterSelf(MakeArg(A), MakeArg(B), MakeArg(C));
    end;

    [TryFunction]
    local procedure TryBefore3(A: Integer; B: Integer; C: Integer)
    begin
        X.AddBeforeSelf(MakeArg(A), MakeArg(B), MakeArg(C));
    end;

    [TryFunction]
    local procedure TryReplace3(A: Integer; B: Integer; C: Integer)
    begin
        X.ReplaceWith(MakeArg(A), MakeArg(B), MakeArg(C));
    end;

    local procedure GetV(Node: XmlCData): Text
    begin
        exit(Node.Value());
    end;

    [TryFunction]
    local procedure TrySetV(NewValue: Text)
    begin
        X.Value(NewValue);
    end;

    [TryFunction]
    local procedure TrySelNodes(XPath: Text)
    begin
        X.SelectNodes(XPath, Lst);
    end;

    [TryFunction]
    local procedure TrySelSingle(XPath: Text; var Found: XmlNode)
    begin
        X.SelectSingleNode(XPath, Found);
    end;

    local procedure SelN(var Observer: Codeunit "Probe Observer"; Name: Text; XPath: Text)
    var
        Ok: Boolean;
        N: XmlNode;
    begin
        Ok := TrySelNodes(XPath);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name + '-err');
        if Ok then begin
            Observer.Observe(Name + '-n', Format(Lst.Count()));
            if Lst.Count() > 0 then begin
                Lst.Get(1, N);
                Observer.Observe(Name + '-first', SerNode(N));
            end
            else
                Observer.Observe(Name + '-first', '');
        end;
    end;

    local procedure SelS(var Observer: Codeunit "Probe Observer"; Name: Text; XPath: Text)
    var
        Ok: Boolean;
        N: XmlNode;
    begin
        Ok := TrySelSingle(XPath, N);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name + '-err');
        if Ok then
            Observer.Observe(Name + '-node', SerNode(N));
    end;

    local procedure ReadBlob(var Blob: Record "LT P90 Blob"): Text
    var
        InS: InStream;
        Line: Text;
        R: Text;
    begin
        Blob.CalcFields(Data);
        Blob.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            R += Line + '|';
        end;
        exit(R);
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [TryFunction]
    local procedure TryMake(Tag: Text)
    begin
        X := MakeX(Tag);
    end;

    local procedure ProbeContent(var Observer: Codeunit "Probe Observer"; Name: Text; Tag: Text)
    var
        Ok: Boolean;
    begin
        Ok := TryMake(Tag);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name + '-err');
        if Ok then
            Observer.Observe(Name + '-x', SerX());
    end;

    [TryFunction]
    local procedure TryUninit(Op: Integer)
    var
        D: XmlDocument;
        P: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
        S: Text;
        E: XmlElement;
    begin
        Res := '';
        case Op of
            1:
                U.Remove();
            2:
                begin
                    E := XmlElement.Create('e');
                    U.AddAfterSelf(E);
                end;
            3:
                begin
                    E := XmlElement.Create('e');
                    U.AddBeforeSelf(E);
                end;
            4:
                begin
                    N := U.AsXmlNode();
                    Res := SerNode(N);
                end;
            5:
                Res := Format(U.GetDocument(D));
            6:
                Res := Format(U.GetParent(P));
            7:
                begin
                    E := XmlElement.Create('e');
                    U.ReplaceWith(E);
                end;
            8:
                Res := Format(U.SelectNodes('.', L));
            9:
                Res := Format(U.SelectSingleNode('.', N));
            10:
                begin
                    U.WriteTo(S);
                    Res := S;
                end;
            11:
                U.WriteTo(OutS);
            12:
                Res := GetV(U);
            13:
                begin
                    X := U;
                    TrySetV('v');
                end;
        end;
    end;

    [Test]
    procedure AsXmlNode_Flags_Attached()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        Observer.Observe('is-element', Format(N.IsXmlElement()));
        Observer.Observe('is-text', Format(N.IsXmlText()));
        Observer.Observe('is-comment', Format(N.IsXmlComment()));
        Observer.Observe('is-cdata', Format(N.IsXmlCData()));
        Observer.Observe('is-pi', Format(N.IsXmlProcessingInstruction()));
        Observer.Observe('is-attribute', Format(N.IsXmlAttribute()));
        Observer.Observe('is-declaration', Format(N.IsXmlDeclaration()));
        Observer.Observe('is-document', Format(N.IsXmlDocument()));
        Observer.Observe('is-documenttype', Format(N.IsXmlDocumentType()));
        Observer.Observe('node-text', SerNode(N));
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_Flags_Detached()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Build(false, 'x');
        N := X.AsXmlNode();
        Observer.Observe('is-element', Format(N.IsXmlElement()));
        Observer.Observe('is-text', Format(N.IsXmlText()));
        Observer.Observe('is-comment', Format(N.IsXmlComment()));
        Observer.Observe('is-cdata', Format(N.IsXmlCData()));
        Observer.Observe('is-pi', Format(N.IsXmlProcessingInstruction()));
        Observer.Observe('is-attribute', Format(N.IsXmlAttribute()));
        Observer.Observe('is-declaration', Format(N.IsXmlDeclaration()));
        Observer.Observe('is-document', Format(N.IsXmlDocument()));
        Observer.Observe('is-documenttype', Format(N.IsXmlDocumentType()));
        Observer.Observe('node-text', SerNode(N));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryCast(Op: Integer)
    var
        N: XmlNode;
    begin
        Res := '';
        N := X.AsXmlNode();
        case Op of
            1:
                Res := SerNode(N.AsXmlElement().AsXmlNode());
            2:
                Res := SerNode(N.AsXmlText().AsXmlNode());
            3:
                Res := SerNode(N.AsXmlComment().AsXmlNode());
            4:
                Res := SerNode(N.AsXmlCData().AsXmlNode());
            5:
                Res := SerNode(N.AsXmlProcessingInstruction().AsXmlNode());
            6:
                Res := SerNode(N.AsXmlAttribute().AsXmlNode());
            7:
                Res := SerNode(N.AsXmlDeclaration().AsXmlNode());
            8:
                Res := SerNode(N.AsXmlDocument().AsXmlNode());
            9:
                Res := SerNode(N.AsXmlDocumentType().AsXmlNode());
        end;
    end;

    local procedure CastRange(var Observer: Codeunit "Probe Observer"; Lo: Integer; Hi: Integer)
    var
        i: Integer;
        Ok: Boolean;
    begin
        for i := Lo to Hi do begin
            Ok := TryCast(i);
            Observer.Observe('cast' + Format(i), Format(Ok));
            Observer.ObserveError('cast' + Format(i) + '-err');
            Observer.Observe('cast' + Format(i) + '-res', Res);
        end;
    end;

    [Test]
    procedure AsXmlNode_CastBack_1To5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        CastRange(Observer, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_CastBack_6To9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        CastRange(Observer, 6, 9);
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_CastBack_Detached()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        CastRange(Observer, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlNode_SharesIdentityWithTypedVariable()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        N2: XmlNode;
        P: XmlElement;
        P2: XmlElement;
        Ok: Boolean;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        N2 := X.AsXmlNode();
        Observer.Observe('same-text', Format(SerNode(N) = SerX()));
        Observer.Observe('node-parent-ok', Format(N.GetParent(P)));
        Observer.Observe('typed-parent-ok', Format(X.GetParent(P2)));
        Observer.Observe('parent-names-equal', Format(P.Name() = P2.Name()));
        N.AddAfterSelf(XmlElement.Create('viaNode'));
        Observer.Observe('doc-after-node-add', SerDoc());
        Ok := TrySetV('changed');
        Observer.Observe('set-value', Format(Ok));
        Observer.Observe('node-sees-change', SerNode(N));
        Observer.Observe('n2-sees-change', SerNode(N2));
        Observer.Observe('get-v', GetV(X));
        Observer.Finish();
    end;

    [Test]
    procedure GetDocument_Attached()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        E: XmlElement;
    begin
        Build(true, 'x');
        Observer.Observe('ok', Format(X.GetDocument(D)));
        Observer.Observe('doc', SerDocOf(D));
        D.GetRoot(E);
        E.SetAttribute('viaD', '1');
        Observer.Observe('original-sees-change', SerDoc());
        Observer.Finish();
    end;

    local procedure SerDocOf(D: XmlDocument): Text
    var
        S: Text;
    begin
        D.WriteTo(S);
        exit(S);
    end;

    [Test]
    procedure GetDocument_Detached_OutputUntouched()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Build(false, 'x');
        Observer.Observe('uninitialised-ok', Format(X.GetDocument(D)));
        D := XmlDocument.Create();
        D.Add(XmlElement.Create('pre'));
        Observer.Observe('preset-ok', Format(X.GetDocument(D)));
        Observer.Observe('preset-doc', SerDocOf(D));
        Observer.Finish();
    end;

    [Test]
    procedure GetDocument_AfterRemove_FreeTree_ViaNode()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        N: XmlNode;
        R2: XmlElement;
        Fresh: XmlCData;
    begin
        Build(true, 'x');
        X.Remove();
        Observer.Observe('after-remove', Format(X.GetDocument(D)));
        Fresh := MakeX('y');
        R2 := XmlElement.Create('free');
        R2.Add(Fresh);
        Observer.Observe('in-free-tree', Format(Fresh.GetDocument(D)));
        D := XmlDocument.Create();
        D.Add(R2);
        Observer.Observe('free-tree-now-in-doc', Format(Fresh.GetDocument(D)));
        Observer.Observe('doc-then', SerDocOf(D));
        Build(true, 'x');
        N := X.AsXmlNode();
        Observer.Observe('via-node', Format(N.GetDocument(D)));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAddToDoc()
    begin
        Doc.Add(X);
    end;

    [Test]
    procedure DocLevel_AddToDocument_ParentAndDocument()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        P: XmlElement;
        Ok: Boolean;
    begin
        Build(false, 'x');
        Doc := XmlDocument.Create();
        Ok := TryAddToDoc();
        Observer.Observe('add-to-doc', Format(Ok));
        Observer.ObserveError('add-to-doc-err');
        asserterror Observer.Observe('doc', SerDoc());
        Observer.ObserveError('af603');
        if Ok then begin
            Observer.Observe('get-document', Format(X.GetDocument(D)));
            Observer.Observe('get-parent', Format(X.GetParent(P)));
            Ok := TryRemove();
            Observer.Observe('remove-at-doc-level', Format(Ok));
            Observer.ObserveError('remove-at-doc-level-err');
            Observer.Observe('doc-after-remove', SerDoc());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure DocLevel_Siblings_AfterRootAdded()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Doc := XmlDocument.Create();
            Ok := TryAddToDoc();
            if Ok then begin
                Doc.Add(XmlElement.Create('r'));
                Ok := TryAfter(i);
                Observer.Observe('k' + Format(i), Format(Ok));
                Observer.ObserveError('k' + Format(i) + '-err');
                Observer.Observe('k' + Format(i) + '-doc', SerDoc());
            end
            else
                Observer.Observe('k' + Format(i), 'x not addable to document');
        end;
        Observer.Finish();
    end;

    [Test]
    procedure DocLevel_BeforeSelf_AndReplace()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Doc := XmlDocument.Create();
            Ok := TryAddToDoc();
            if Ok then begin
                Doc.Add(XmlElement.Create('r'));
                Ok := TryBefore(i);
                Observer.Observe('b' + Format(i), Format(Ok));
                Observer.ObserveError('b' + Format(i) + '-err');
                Observer.Observe('b' + Format(i) + '-doc', SerDoc());
                Ok := TryReplace(i);
                Observer.Observe('r' + Format(i), Format(Ok));
                Observer.ObserveError('r' + Format(i) + '-err');
                Observer.Observe('r' + Format(i) + '-doc', SerDoc());
            end
            else
                Observer.Observe('k' + Format(i), 'x not addable to document');
        end;
        Observer.Finish();
    end;

    [Test]
    procedure GetParent_Attached_Positions()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        N: XmlNode;
        Pos: Integer;
    begin
        for Pos := 0 to 3 do begin
            BuildAt(true, Pos, 'x');
            Observer.Observe('p' + Format(Pos), Format(X.GetParent(P)));
            Observer.Observe('p' + Format(Pos) + '-name', P.Name());
            Observer.Observe('p' + Format(Pos) + '-via-node', Format(X.AsXmlNode().GetParent(P)));
        end;
        BuildAt(true, 2, 'x');
        X.GetParent(P);
        Observer.Observe('parent-xml', SerNode(P.AsXmlNode()));
        P.SetAttribute('viaP', '1');
        Observer.Observe('doc-after-parent-change', SerDoc());
        Observer.Finish();
    end;

    [Test]
    procedure GetParent_Detached_OutputUntouched()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
    begin
        Build(false, 'x');
        Observer.Observe('uninitialised-ok', Format(X.GetParent(P)));
        P := XmlElement.Create('pre');
        Observer.Observe('preset-ok', Format(X.GetParent(P)));
        Observer.Observe('preset-name', P.Name());
        Observer.Observe('via-node', Format(X.AsXmlNode().GetParent(P)));
        Observer.Finish();
    end;

    [Test]
    procedure GetParent_AfterRemove_FreeTree()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        R2: XmlElement;
        Fresh: XmlCData;
    begin
        Build(true, 'x');
        X.Remove();
        P := XmlElement.Create('pre');
        Observer.Observe('after-remove', Format(X.GetParent(P)));
        Observer.Observe('after-remove-name', P.Name());
        Fresh := MakeX('y');
        R2 := XmlElement.Create('free');
        R2.Add(Fresh);
        Observer.Observe('in-free-tree', Format(Fresh.GetParent(P)));
        Observer.Observe('in-free-tree-name', P.Name());
        R2.Add(Fresh);
        Observer.Observe('added-twice-child-count', Format(R2.GetChildNodes().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Relative_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '.');
        SelN(Observer, 'x2', 'self::node()');
        SelN(Observer, 'x3', '..');
        SelN(Observer, 'x4', 'following-sibling::*');
        SelN(Observer, 'x5', 'preceding-sibling::*');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Relative_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'following-sibling::node()');
        SelN(Observer, 'x2', '../*');
        SelN(Observer, 'x3', '../node()');
        SelN(Observer, 'x4', 'parent::r');
        SelN(Observer, 'x5', 'ancestor::*');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Relative_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'self::text()');
        SelN(Observer, 'x2', 'self::comment()');
        SelN(Observer, 'x3', 'self::processing-instruction()');
        SelN(Observer, 'x4', 'text()');
        SelN(Observer, 'x5', 'child::node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Relative_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '@*');
        SelN(Observer, 'x2', 'following-sibling::b');
        SelN(Observer, 'x3', 'preceding-sibling::a');
        SelN(Observer, 'x4', '../a');
        SelN(Observer, 'x5', 'descendant-or-self::node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Absolute_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/r');
        SelN(Observer, 'x2', '/r/a');
        SelN(Observer, 'x3', '/r/node()');
        SelN(Observer, 'x4', '//a');
        SelN(Observer, 'x5', '//node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Absolute_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/r/text()');
        SelN(Observer, 'x2', '/r/comment()');
        SelN(Observer, 'x3', '/r/processing-instruction()');
        SelN(Observer, 'x4', '/');
        SelN(Observer, 'x5', '/r/node()[2]');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Absolute_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/*');
        SelN(Observer, 'x2', '/r/*');
        SelN(Observer, 'x3', '//*[1]');
        SelN(Observer, 'x4', '/r/a/following-sibling::node()');
        SelN(Observer, 'x5', '/r/b/preceding-sibling::node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_NoMatch_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'nomatch');
        SelN(Observer, 'x2', '/nomatch');
        SelN(Observer, 'x3', 'self::nomatch');
        SelN(Observer, 'x4', '../zzz');
        SelN(Observer, 'x5', '//zzz');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_NoMatch_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/r/a/b');
        SelN(Observer, 'x2', '/r/node()[9]');
        SelN(Observer, 'x3', 'text()[2]');
        SelN(Observer, 'x4', 'following-sibling::zzz');
        SelN(Observer, 'x5', 'ancestor::zzz');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_InvalidXPath_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '');
        SelN(Observer, 'x2', ' ');
        SelN(Observer, 'x3', '[');
        SelN(Observer, 'x4', 'count(.)');
        SelN(Observer, 'x5', '$v');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_InvalidXPath_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '1 + 1');
        SelN(Observer, 'x2', '"str"');
        SelN(Observer, 'x3', 'a b');
        SelN(Observer, 'x4', '/r/a[');
        SelN(Observer, 'x5', 'name()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_InvalidXPath_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'true()');
        SelN(Observer, 'x2', '//');
        SelN(Observer, 'x3', '@@');
        SelN(Observer, 'x4', 'x:y');
        SelN(Observer, 'x5', 'self::');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Detached_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelN(Observer, 'x1', '.');
        SelN(Observer, 'x2', '..');
        SelN(Observer, 'x3', 'self::node()');
        SelN(Observer, 'x4', '/');
        SelN(Observer, 'x5', '/r');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_Detached_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelN(Observer, 'x1', 'following-sibling::*');
        SelN(Observer, 'x2', 'ancestor::node()');
        SelN(Observer, 'x3', 'parent::node()');
        SelN(Observer, 'x4', 'preceding-sibling::node()');
        SelN(Observer, 'x5', '//*');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Relative_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '.');
        SelS(Observer, 'x2', 'self::node()');
        SelS(Observer, 'x3', '..');
        SelS(Observer, 'x4', 'following-sibling::*');
        SelS(Observer, 'x5', 'preceding-sibling::*');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Relative_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'following-sibling::node()');
        SelS(Observer, 'x2', '../*');
        SelS(Observer, 'x3', '../node()');
        SelS(Observer, 'x4', 'parent::r');
        SelS(Observer, 'x5', 'ancestor::*');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Relative_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'self::text()');
        SelS(Observer, 'x2', 'self::comment()');
        SelS(Observer, 'x3', 'self::processing-instruction()');
        SelS(Observer, 'x4', 'text()');
        SelS(Observer, 'x5', 'child::node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Relative_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '@*');
        SelS(Observer, 'x2', 'following-sibling::b');
        SelS(Observer, 'x3', 'preceding-sibling::a');
        SelS(Observer, 'x4', '../a');
        SelS(Observer, 'x5', 'descendant-or-self::node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Absolute_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/r');
        SelS(Observer, 'x2', '/r/a');
        SelS(Observer, 'x3', '/r/node()');
        SelS(Observer, 'x4', '//a');
        SelS(Observer, 'x5', '//node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Absolute_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/r/text()');
        SelS(Observer, 'x2', '/r/comment()');
        SelS(Observer, 'x3', '/r/processing-instruction()');
        SelS(Observer, 'x4', '/');
        SelS(Observer, 'x5', '/r/node()[2]');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Absolute_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/*');
        SelS(Observer, 'x2', '/r/*');
        SelS(Observer, 'x3', '//*[1]');
        SelS(Observer, 'x4', '/r/a/following-sibling::node()');
        SelS(Observer, 'x5', '/r/b/preceding-sibling::node()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_NoMatch_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'nomatch');
        SelS(Observer, 'x2', '/nomatch');
        SelS(Observer, 'x3', 'self::nomatch');
        SelS(Observer, 'x4', '../zzz');
        SelS(Observer, 'x5', '//zzz');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_NoMatch_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/r/a/b');
        SelS(Observer, 'x2', '/r/node()[9]');
        SelS(Observer, 'x3', 'text()[2]');
        SelS(Observer, 'x4', 'following-sibling::zzz');
        SelS(Observer, 'x5', 'ancestor::zzz');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_InvalidXPath_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '');
        SelS(Observer, 'x2', ' ');
        SelS(Observer, 'x3', '[');
        SelS(Observer, 'x4', 'count(.)');
        SelS(Observer, 'x5', '$v');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_InvalidXPath_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '1 + 1');
        SelS(Observer, 'x2', '"str"');
        SelS(Observer, 'x3', 'a b');
        SelS(Observer, 'x4', '/r/a[');
        SelS(Observer, 'x5', 'name()');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_InvalidXPath_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'true()');
        SelS(Observer, 'x2', '//');
        SelS(Observer, 'x3', '@@');
        SelS(Observer, 'x4', 'x:y');
        SelS(Observer, 'x5', 'self::');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Detached_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelS(Observer, 'x1', '.');
        SelS(Observer, 'x2', '..');
        SelS(Observer, 'x3', 'self::node()');
        SelS(Observer, 'x4', '/');
        SelS(Observer, 'x5', '/r');
        Observer.Finish();
    end;

    [Test]
    procedure SelectSingle_Detached_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelS(Observer, 'x1', 'following-sibling::*');
        SelS(Observer, 'x2', 'ancestor::node()');
        SelS(Observer, 'x3', 'parent::node()');
        SelS(Observer, 'x4', 'preceding-sibling::node()');
        SelS(Observer, 'x5', '//*');
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_ListAfterNoMatch_AndViaNode()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        Ok: Boolean;
        Found: XmlNode;
    begin
        Build(true, 'x');
        Ok := TrySelNodes('../*');
        Observer.Observe('first', Format(Ok));
        Observer.Observe('first-count', Format(Lst.Count()));
        Ok := TrySelNodes('nomatch');
        Observer.Observe('second-nomatch', Format(Ok));
        Observer.Observe('count-after-nomatch', Format(Lst.Count()));
        N := X.AsXmlNode();
        Observer.Observe('via-node-nodes', Format(N.SelectNodes('../*', Lst)));
        Observer.Observe('via-node-count', Format(Lst.Count()));
        Observer.Observe('via-node-single', Format(N.SelectSingleNode('..', Found)));
        Observer.Observe('via-node-single-text', SerNode(Found));
        Observer.Observe('via-node-single-nomatch', Format(N.SelectSingleNode('nomatch', Found)));
        Observer.Observe('found-after-nomatch', SerNode(Found));
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_Contents_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeContent(Observer, 'empty', '');
        ProbeContent(Observer, 'space', ' ');
        ProbeContent(Observer, 'plain', 'a b');
        ProbeContent(Observer, 'markup', '<&>');
        ProbeContent(Observer, 'cdata-end', ']]>');
        ProbeContent(Observer, 'double-dash', '--');
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_Contents_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeContent(Observer, 'trailing-dash', 'a-');
        ProbeContent(Observer, 'leading-dash', '-a');
        ProbeContent(Observer, 'pi-end', '?>');
        ProbeContent(Observer, 'newline', 'x' + Lf() + 'y');
        ProbeContent(Observer, 'unicode', 'aü€');
        ProbeContent(Observer, 'padded', '  p  ');
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_Text_AttachedAndDetached_NoLeakage()
    var
        Observer: Codeunit "Probe Observer";
        S: Text;
        N: XmlNode;
    begin
        Build(true, 'x');
        S := 'preset';
        X.WriteTo(S);
        Observer.Observe('attached', S);
        N := X.AsXmlNode();
        N.WriteTo(S);
        Observer.Observe('attached-via-node', S);
        Observer.Observe('doc', SerDoc());
        Build(false, 'x');
        S := 'preset';
        X.WriteTo(S);
        Observer.Observe('detached', S);
        Observer.Observe('length', Format(StrLen(S)));
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_Document_AfterEachChange()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Observer.Observe('initial', SerDoc());
        Ok := TrySetV('changed');
        Observer.Observe('after-set-value', SerDoc());
        Ok := TryAfter(1);
        Observer.Observe('after-add-after', SerDoc());
        Ok := TryBefore(3);
        Observer.Observe('after-add-before', SerDoc());
        Ok := TryReplace(2);
        Observer.Observe('after-replace', SerDoc());
        Build(true, 'x');
        Ok := TryRemove();
        Observer.Observe('after-remove', SerDoc());
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_Special_1()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Observer.Observe('initial', GetV(X));
        Ok := TrySetV('');
        Observer.Observe('empty', Format(Ok));
        Observer.ObserveError('empty-err');
        Observer.Observe('empty-doc', SerDoc());
        Ok := TrySetV('<&>');
        Observer.Observe('markup', Format(Ok));
        Observer.ObserveError('markup-err');
        Observer.Observe('markup-doc', SerDoc());
        Observer.Observe('markup-get', GetV(X));
        Ok := TrySetV(']]>');
        Observer.Observe('cdata-end', Format(Ok));
        Observer.ObserveError('cdata-end-err');
        Observer.Observe('cdata-end-doc', SerDoc());
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_Special_2()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TrySetV('--');
        Observer.Observe('double-dash', Format(Ok));
        Observer.ObserveError('double-dash-err');
        Observer.Observe('double-dash-doc', SerDoc());
        Ok := TrySetV('?>');
        Observer.Observe('pi-end', Format(Ok));
        Observer.ObserveError('pi-end-err');
        Observer.Observe('pi-end-doc', SerDoc());
        Ok := TrySetV('x' + Lf() + 'y');
        Observer.Observe('newline', Format(Ok));
        Observer.ObserveError('newline-err');
        Observer.Observe('newline-doc', SerDoc());
        Observer.Observe('newline-get', GetV(X));
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(false, 'x');
        Ok := TrySetV('new');
        Observer.Observe('set', Format(Ok));
        Observer.ObserveError('set-err');
        Observer.Observe('x', SerX());
        Observer.Observe('get', GetV(X));
        Observer.Finish();
    end;

    local procedure Prepare(var Blob: Record "LT P90 Blob")
    begin
        Blob.DeleteAll();
        Blob.Init();
        Blob.Id := 1;
        Blob.Data.CreateOutStream(OutS);
    end;

    [Test]
    procedure WriteTo_OutStream_Attached_AndText()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
        S: Text;
    begin
        Build(true, 'x');
        Prepare(Blob);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        X.WriteTo(S);
        Observer.Observe('blob', ReadBlob(Blob));
        Observer.Observe('blob-length', Format(Blob.Data.Length()));
        Observer.Observe('text', S);
        Observer.Observe('text-length', Format(StrLen(S)));
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_OutStream_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
    begin
        Build(false, 'x');
        Prepare(Blob);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('blob', ReadBlob(Blob));
        Observer.Observe('blob-length', Format(Blob.Data.Length()));
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_OutStream_ViaXmlNode_AndDocument()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
        N: XmlNode;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        Prepare(Blob);
        N.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('node-blob', ReadBlob(Blob));
        Observer.Observe('node-blob-length', Format(Blob.Data.Length()));
        TryAfter(1);
        Prepare(Blob);
        Doc.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('doc-blob', ReadBlob(Blob));
        Observer.Observe('doc-blob-length', Format(Blob.Data.Length()));
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_OutStream_TwiceIntoSameStream()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
    begin
        Build(true, 'x');
        Prepare(Blob);
        X.WriteTo(OutS);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('blob', ReadBlob(Blob));
        Observer.Observe('blob-length', Format(Blob.Data.Length()));
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_OutStream_AfterReplaceAndRemove()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
    begin
        Build(true, 'x');
        TryReplace(1);
        Prepare(Blob);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('replaced-x-blob', ReadBlob(Blob));
        Prepare(Blob);
        Doc.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('replaced-doc-blob', ReadBlob(Blob));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryWriteUninitStream()
    var
        S2: OutStream;
    begin
        X.WriteTo(S2);
    end;

    [Test]
    procedure WriteTo_OutStream_UninitialisedStream()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryWriteUninitStream();
        Observer.Observe('uninitialised-stream', Format(Ok));
        Observer.ObserveError('uninitialised-stream-err');
        Observer.Finish();
    end;

    [Test]
    procedure UninitialisedVariable_1()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Ok := TryUninit(i);
            Observer.Observe('op' + Format(i), Format(Ok));
            Observer.ObserveError('op' + Format(i) + '-err');
            Observer.Observe('op' + Format(i) + '-res', Res);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure UninitialisedVariable_2()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 10 do begin
            Ok := TryUninit(i);
            Observer.Observe('op' + Format(i), Format(Ok));
            Observer.ObserveError('op' + Format(i) + '-err');
            Observer.Observe('op' + Format(i) + '-res', Res);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure UninitialisedVariable_3()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Ok: Boolean;
    begin
        for i := 11 to 13 do begin
            Ok := TryUninit(i);
            Observer.Observe('op' + Format(i), Format(Ok));
            Observer.ObserveError('op' + Format(i) + '-err');
            Observer.Observe('op' + Format(i) + '-res', Res);
        end;
        Observer.Finish();
    end;

}
