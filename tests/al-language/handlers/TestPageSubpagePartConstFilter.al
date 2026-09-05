// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: TSPL Header (60320), TSPL Line (60321), TSPL Lines (60322), TSPL Card (60323); shared Assert (60021)
//
/// <summary>
/// Pins what a subpage part shows when its SubPageLink uses const(...) or filter(...),
/// alone or next to a field(...) link -- the FactBox / typed-lines shape (e.g. Base
/// Application's "Approval Comment Sub Form" hosted with "Table ID" = const(Database::...)).
///
/// The claims, each in its own test:
///   - const(<option member>) pins the part's field to that member.
///   - filter(<expression>) restricts the part to rows inside the expression.
///   - const(Database::<table>) pins an Integer field to that table's id.
///   - const('<text>') pins a Code field to that literal.
///   - a const(...)-only link (no field(...) at all) still filters the part.
///   - New() through a const(...)-linked part starts the row with the constant already
///     stamped, the same way a field(...) link stamps the parent's key.
///   - New() through a filter(...)-linked part with a multi-value expression stamps NOTHING
///     into that field -- there is no single value to stamp.
///
/// The negatives are in the data: every header carries a row each part must NOT show
/// (wrong Kind, wrong Status, wrong Table ID) and a second header carries a row that would
/// pass the const/filter alone, so a part that applied only the field(...) link, or only
/// the const/filter, or nothing, surfaces a row the assertions reject by name.
/// </summary>
codeunit 60324 "TSPL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure AddLine(HeaderNo: Code[20]; LineNo: Integer; Kind: Option Comment,Attachment; Status: Option "None",Open,Released,Closed; Name: Text[50]; TableId: Integer; Category: Code[10])
    var
        Line: Record "TSPL Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Kind := Kind;
        Line.Status := Status;
        Line.Name := Name;
        Line."Table ID" := TableId;
        Line.Category := Category;
        Line.Insert();
    end;

    local procedure Initialize()
    var
        Header: Record "TSPL Header";
        Line: Record "TSPL Line";
    begin
        Header.DeleteAll();
        Line.DeleteAll();

        Header.Init();
        Header."No." := 'H1';
        Header.Descr := 'First';
        Header.Insert();

        Header.Init();
        Header."No." := 'H2';
        Header.Descr := 'Second';
        Header.Insert();

        // H1: one row per combination the parts have to tell apart.
        AddLine('H1', 1, Line.Kind::Comment, Line.Status::Open, 'C-Open', 0, '');
        AddLine('H1', 2, Line.Kind::Attachment, Line.Status::Open, 'A-Open', Database::"TSPL Header", 'SPECIAL');
        AddLine('H1', 3, Line.Kind::Attachment, Line.Status::Closed, 'A-Closed', 0, 'SPECIAL');
        AddLine('H1', 4, Line.Kind::Comment, Line.Status::Released, 'C-Rel', Database::"TSPL Header", '');
        // H2: passes every const/filter on its own, so it only stays hidden if the
        // field("No.") half of the link is applied too.
        AddLine('H2', 1, Line.Kind::Attachment, Line.Status::Open, 'Foreign', Database::"TSPL Header", 'SPECIAL');
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "TSPL Card")
    var
        Header: Record "TSPL Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    // Each helper walks one part of the card and returns the Names it shows, in order, as
    // 'A;B;C;'. One helper per part because a TestPage part cannot be passed as a var
    // TestPage parameter. An insertable part enumerates one extra synthetic row past the
    // real data -- "Line No." 0 with every field blank, the template row New() would fill
    // in -- which is not a persisted line and is not counted.
    local procedure ConstLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstLines.First() then
            exit('');
        repeat
            if Card.ConstLines."Line No.".Value <> '0' then
                Names += Card.ConstLines.Name.Value + ';';
        until not Card.ConstLines.Next();
    end;

    local procedure FilterLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.FilterLines.First() then
            exit('');
        repeat
            if Card.FilterLines."Line No.".Value <> '0' then
                Names += Card.FilterLines.Name.Value + ';';
        until not Card.FilterLines.Next();
    end;

    local procedure ConstTableLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstTableLines.First() then
            exit('');
        repeat
            if Card.ConstTableLines."Line No.".Value <> '0' then
                Names += Card.ConstTableLines.Name.Value + ';';
        until not Card.ConstTableLines.Next();
    end;

    local procedure ConstCodeLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstCodeLines.First() then
            exit('');
        repeat
            if Card.ConstCodeLines."Line No.".Value <> '0' then
                Names += Card.ConstCodeLines.Name.Value + ';';
        until not Card.ConstCodeLines.Next();
    end;

    local procedure ConstOnlyLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstOnlyLines.First() then
            exit('');
        repeat
            if Card.ConstOnlyLines."Line No.".Value <> '0' then
                Names += Card.ConstOnlyLines.Name.Value + ';';
        until not Card.ConstOnlyLines.Next();
    end;

    // CLAIM: Kind = const(Attachment) next to a field(...) link shows exactly the current
    // header's Attachment rows -- not its Comment rows, not another header's Attachment.
    [Test]
    procedure ConstLink_ShowsOnlyTheHeadersRowsMatchingTheConstant()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('A-Open;A-Closed;', ConstLinesNames(Card),
            'a const(Attachment) link must show exactly header H1''s two Attachment rows');
        Card.Close();
    end;

    // CLAIM: Status = filter(Open | Released) next to a field(...) link shows exactly the
    // current header's rows whose Status is inside the expression.
    [Test]
    procedure FilterLink_ShowsOnlyTheHeadersRowsInsideTheExpression()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('C-Open;A-Open;C-Rel;', FilterLinesNames(Card),
            'a filter(Open | Released) link must show exactly header H1''s Open and Released rows');
        Card.Close();
    end;

    // CLAIM: "Table ID" = const(Database::"TSPL Header") pins the Integer field to that
    // table's object id.
    [Test]
    procedure ConstDatabaseLink_PinsTheFieldToTheTableId()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('A-Open;C-Rel;', ConstTableLinesNames(Card),
            'a const(Database::"TSPL Header") link must show exactly header H1''s rows carrying that table id');
        Card.Close();
    end;

    // CLAIM: Category = const('SPECIAL') pins a Code field to the quoted literal.
    [Test]
    procedure ConstTextLink_PinsTheCodeFieldToTheLiteral()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('A-Open;A-Closed;', ConstCodeLinesNames(Card),
            'a const(''SPECIAL'') link must show exactly header H1''s rows whose Category is SPECIAL');
        Card.Close();
    end;

    // CLAIM: a SubPageLink made of a single const(...) entry, with no field(...) at all,
    // still filters the part -- to every header's Comment rows, since nothing ties it to
    // the current header.
    [Test]
    procedure ConstOnlyLink_FiltersWithoutAnyFieldLink()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('C-Open;C-Rel;', ConstOnlyLinesNames(Card),
            'a const(Comment)-only link must show exactly the Comment rows, across headers');
        Card.Close();
    end;

    // CLAIM: New() through a const(...)-linked part starts the row with the constant
    // already stamped, exactly as the field(...) half stamps the header key. The test never
    // sets Kind, so Attachment (a non-default member) can only have come from the link.
    [Test]
    procedure ConstLink_NewStampsTheConstantOntoTheNewRow()
    var
        Line: Record "TSPL Line";
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.ConstLines.New();
        Card.ConstLines."Line No.".SetValue(9);
        Card.ConstLines.Name.SetValue('New-A');
        Card.Close();

        Assert.IsTrue(Line.Get('H1', 9), 'New() through the part must have inserted line 9 under header H1');
        Assert.AreEqual(Format(Line.Kind::Attachment), Format(Line.Kind),
            'the const(Attachment) link must have stamped Kind onto the new row');
        Assert.AreEqual('New-A', Line.Name, 'the value set through the part must have been persisted');
    end;

    // CLAIM: New() through a part linked by a multi-value filter(...) stamps nothing into
    // that field -- Status stays at its Init() value, which the fixture deliberately keeps
    // OUTSIDE the filter (member "None") so an accidental stamp of the first selected
    // member is distinguishable from no stamp at all.
    [Test]
    procedure FilterLink_NewDoesNotStampAMultiValueExpression()
    var
        Line: Record "TSPL Line";
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.FilterLines.New();
        Card.FilterLines."Line No.".SetValue(9);
        Card.FilterLines.Name.SetValue('New-F');
        Card.Close();

        Assert.IsTrue(Line.Get('H1', 9), 'New() through the part must have inserted line 9 under header H1');
        Assert.AreEqual('H1', Line."Header No.", 'the field("No.") half of the link must still have stamped the header key');
        Assert.AreEqual(Format(Line.Status::"None"), Format(Line.Status),
            'a filter(Open | Released) link has no single value to stamp, so Status must stay at its Init() value');
    end;
}
