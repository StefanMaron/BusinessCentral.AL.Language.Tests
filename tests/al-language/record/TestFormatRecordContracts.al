// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained enum 68830, table 68831, codeunit 68832
// Probe: written against a real BC 27.5 service tier on Linux (en-US); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins Format of a record variable as a whole (Base Application compares Format(Rec) = Format(xRec)):
//  - the text is the Format of each field joined by a TAB (character 9), with no leading or trailing separator;
//  - the normal fields come first, in field number order, and the FlowFields come after all of them (here
//    the FlowField has field number 9 and is the LAST item);
//  - a FlowField shows the value it holds: 0 until CalcFields, then the calculated one;
//  - a Blob shows * when it holds data and one space when it does not; a Guid with its braces; an Option and an
//    Enum by caption (a cleared record shows the first members);
//  - two records that differ in one field, a FlowField included, format differently; copies format alike;
//  - Format(RecordRef) is the same text and Format(FieldRef) is the Format of the field.
// BC versions: 27.5

enum 68830 "Probe FmtRec Enum"
{
    Extensible = true;

    value(0; Zero) { Caption = 'Zero cap'; }
    value(1; One) { Caption = 'One cap'; }
}

table 68831 "Probe FmtRec Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Cod; Code[10]) { }
        field(2; Txt; Text[30]) { }
        field(3; Int; Integer) { }
        field(4; Dec; Decimal) { }
        field(5; Bl; Boolean) { }
        field(6; Dt; Date) { }
        field(7; Opt; Option)
        {
            OptionMembers = Alpha,Beta;
            OptionCaption = 'Alpha cap,Beta cap';
        }
        field(8; En; Enum "Probe FmtRec Enum") { }
        field(9; Flow; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Probe FmtRec Table");
        }
        field(10; Blb; Blob) { }
        field(11; Gd; Guid) { }
        field(12; Tm; Time) { }
        field(13; Dtm; DateTime) { }
        field(14; Big; BigInteger) { }
        field(15; Dur; Duration) { }
    }

    keys
    {
        key(PK; Cod) { Clustered = true; }
    }
}

codeunit 68832 "Probe Format Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Filled(var FmtRec: Record "Probe FmtRec Table")
    var
        OutStr: OutStream;
    begin
        FmtRec.DeleteAll();
        FmtRec.Init();
        FmtRec.Cod := 'K1';
        FmtRec.Txt := 'hello';
        FmtRec.Int := 42;
        FmtRec.Dec := 1234.5;
        FmtRec.Bl := true;
        FmtRec.Dt := DMY2Date(5, 3, 2024);
        FmtRec.Opt := FmtRec.Opt::Beta;
        FmtRec.En := FmtRec.En::One;
        FmtRec.Gd := '{11111111-2222-3333-4444-555555555555}';
        FmtRec.Tm := 123456T;
        FmtRec.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), 123456T);
        FmtRec.Big := 99;
        FmtRec.Dur := 90061001;
        FmtRec.Blb.CreateOutStream(OutStr);
        OutStr.WriteText('blob');
        FmtRec.Insert();
    end;

    local procedure Expected(FmtRec: Record "Probe FmtRec Table"; BlobText: Text; FlowText: Text): Text
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        exit(
            Format(FmtRec.Cod) + Tab + Format(FmtRec.Txt) + Tab + Format(FmtRec.Int) + Tab + Format(FmtRec.Dec) + Tab +
            Format(FmtRec.Bl) + Tab + Format(FmtRec.Dt) + Tab + Format(FmtRec.Opt) + Tab + Format(FmtRec.En) + Tab +
            BlobText + Tab + Format(FmtRec.Gd) + Tab + Format(FmtRec.Tm) + Tab + Format(FmtRec.Dtm) + Tab +
            Format(FmtRec.Big) + Tab + Format(FmtRec.Dur) + Tab + FlowText);
    end;

    [Test]
    procedure FormatRecord_IsTheFieldsJoinedByTab_FlowFieldsLast()
    var
        FmtRec: Record "Probe FmtRec Table";
    begin
        Filled(FmtRec);

        Assert.AreEqual(Expected(FmtRec, '*', '0'), Format(FmtRec), 'FlowField not calculated');
        Assert.IsTrue(Format(FmtRec).StartsWith('K1' + TabText() + 'hello' + TabText() + '42' + TabText() + '1,234.5' + TabText() + 'Yes' + TabText() + '03/05/24' + TabText() + 'Beta cap' + TabText() + 'One cap' + TabText() + '*' + TabText() + '{11111111-2222-3333-4444-555555555555}' + TabText()), 'start of the text');

        FmtRec.CalcFields(Flow);
        Assert.AreEqual(Expected(FmtRec, '*', '1'), Format(FmtRec), 'FlowField calculated');
    end;

    local procedure TabText(): Text
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        exit(Tab);
    end;

    [Test]
    procedure FormatRecord_ClearedRecord_ShowsInitialValues()
    var
        FmtRec: Record "Probe FmtRec Table";
    begin
        Assert.AreEqual(Expected(FmtRec, Format(FmtRec.Blb), '0'), Format(FmtRec), 'cleared');
        Assert.IsTrue(Format(FmtRec).StartsWith(TabText() + TabText() + '0' + TabText() + '0' + TabText() + 'No' + TabText() + TabText() + 'Alpha cap' + TabText() + 'Zero cap' + TabText() + ' ' + TabText() + '{00000000-0000-0000-0000-000000000000}' + TabText()), 'start of the text: first members, a blank Blob (one space), the null Guid');
    end;

    [Test]
    procedure FormatRecord_DiffersWithAnyOneField_AndNotForCopies()
    var
        FmtRec: Record "Probe FmtRec Table";
        Other: Record "Probe FmtRec Table";
    begin
        Filled(FmtRec);
        Other := FmtRec;
        Assert.AreEqual(Format(FmtRec), Format(Other), 'a copy');

        Other.Txt := 'hellp';
        Assert.AreNotEqual(Format(FmtRec), Format(Other), 'Text');
        Other := FmtRec;
        Other.Int := 43;
        Assert.AreNotEqual(Format(FmtRec), Format(Other), 'Integer');
        Other := FmtRec;
        Other.Dec := 1234.51;
        Assert.AreNotEqual(Format(FmtRec), Format(Other), 'Decimal');
        Other := FmtRec;
        Other.Flow := 7;
        Assert.AreNotEqual(Format(FmtRec), Format(Other), 'FlowField');
    end;

    [Test]
    procedure FormatRecordRefAndFieldRef_FollowTheRecord()
    var
        FmtRec: Record "Probe FmtRec Table";
        FmtRef: RecordRef;
        FldRef: FieldRef;
    begin
        Filled(FmtRec);
        FmtRef.GetTable(FmtRec);

        Assert.AreEqual(Format(FmtRec), Format(FmtRef), 'RecordRef');
        FldRef := FmtRef.Field(4);
        Assert.AreEqual('1,234.5', Format(FldRef), 'decimal field');
        FldRef := FmtRef.Field(2);
        Assert.AreEqual('hello', Format(FldRef), 'text field');
    end;
}
