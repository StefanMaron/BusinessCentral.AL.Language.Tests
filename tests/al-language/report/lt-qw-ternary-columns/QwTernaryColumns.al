// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 87500, report 87501, report extension 87502, test codeunit 87503
// Probe (corpus issue 685 section 1, from a user report): a ternary expression as the source of a report dataset column, with a Label,
// or a field as a branch, and ternary columns of Decimal, Integer, Date, Boolean, Option and Enum. Each test saves the
// dataset as XML (Report.SaveAs, ReportFormat::Xml) for one row with Flag = true or Flag = false and reads every Column line.
// IncludeCaption on a ternary column does not compile (AL0385, tests/must-not-compile/cases/0015).
// BC versions: 27.5+

table 87500 "LT QW Tern Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
        field(3; Name; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; Qty; Integer) { }
        field(6; D; Date) { }
        field(7; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(8; E; Enum "Sales Document Type") { }
        field(9; Flag2; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 87501 "LT QW Tern Columns"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(EmptyOrLbl; Row.Flag ? '' : LblA) { }
            column(LblOrEmpty; Row.Flag ? LblA : '') { }
            column(LblOrLbl; Row.Flag ? LblA : LblB) { }
            column(LblOrField; Row.Flag ? LblA : Row.Name) { }
            column(FieldOrLbl; Row.Flag ? Row.Name : LblA) { }
#if LTQW_TEXTCONST_PROBE
            // A TextConst branch compiles, but BC 29.0 refuses to publish the app: "Failure while emitting object. Object:'Report "LT QW Tern
            // Columns"' (Unexpected value 'TextConst' of type 'Microsoft.Dynamics.Nav.CodeAnalysis.NavTypeKind')" (corpus CI run 39741827358).
            column(TcOrLbl; Row.Flag ? TcA : LblA) { }
#endif
            column(DecCol; Row.Flag ? Row.Amount : 0) { }
            column(IntOrDec; Row.Flag ? 7 : Row.Amount) { }
            column(IntCol; Row.Flag ? Row.Qty : 7) { }
            column(DateCol; Row.Flag ? Row.D : 0D) { }
            column(BoolCol; Row.Flag ? Row.Flag2 : true) { }
            column(OptCol; Row.Flag ? Row.Opt : Row.Opt::Gamma) { }
            column(EnumCol; Row.Flag ? Row.E : Row.E::Order) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
#if LTQW_TEXTCONST_PROBE
        TcA: TextConst ENU = 'Text const A';
#endif
}

reportextension 87502 "LT QW Tern Columns Ext" extends "LT QW Tern Columns"
{
    dataset
    {
        add(Row)
        {
            column(ExtEmptyOrLbl; Row.Flag ? '' : ExtLbl) { }
            column(ExtLblOrField; Row.Flag ? ExtLbl : Row.Name) { }
            column(ExtDec; Row.Flag ? Row.Amount : 1) { }
            column(ExtEnum; Row.Flag ? Row.E : Row.E::Quote) { }
        }
    }

    var
        ExtLbl: Label 'Ext label';
}

codeunit 87503 "LT QW Tern Column Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Flag: Boolean)
    var
        Row: Record "LT QW Tern Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Flag := Flag;
        Row.Name := 'Field name';
        Row.Amount := 12.5;
        Row.Qty := 3;
        Row.D := DMY2Date(15, 3, 2024);
        Row.Opt := Row.Opt::Beta;
        Row.E := Row.E::Invoice;
        Row.Flag2 := false;
        Row.Insert();
    end;

    // Every Column line of the XML dataset whose name starts with Prefix, trimmed, in dataset order.
    local procedure Columns(Prefix: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT QW Tern Columns", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column name="' + Prefix) then
                Result += '[' + Line + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure QW_TernaryColumns_FlagTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Observer.Observe('labels', Columns('EmptyOrLbl') + Columns('LblOr') + Columns('FieldOrLbl') + Columns('TcOrLbl'));
        Observer.Observe('scalars', Columns('DecCol') + Columns('IntOrDec') + Columns('IntCol') + Columns('DateCol') + Columns('BoolCol'));
        Observer.Observe('option_enum', Columns('OptCol') + Columns('EnumCol'));
        Observer.Observe('extension', Columns('Ext'));
        Observer.Finish();
    end;

    [Test]
    procedure QW_TernaryColumns_FlagFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Observer.Observe('labels', Columns('EmptyOrLbl') + Columns('LblOr') + Columns('FieldOrLbl') + Columns('TcOrLbl'));
        Observer.Observe('scalars', Columns('DecCol') + Columns('IntOrDec') + Columns('IntCol') + Columns('DateCol') + Columns('BoolCol'));
        Observer.Observe('option_enum', Columns('OptCol') + Columns('EnumCol'));
        Observer.Observe('extension', Columns('Ext'));
        Observer.Finish();
    end;
}
