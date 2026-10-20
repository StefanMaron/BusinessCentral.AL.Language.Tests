// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 86500, pages 86501 and 86502, log codeunit 86503 (used only by test codeunit 86504),
//   test codeunit 86504; Base Application's Sales Header / Sales Line and its OnResolveCaptionClass subscribers (areas 1, 2, 5, 101).
// Probe: writer QD, for the al-runtime-rs refusal "a CaptionClass expression result with another area" (the top Tests-ERM refusal) and the
//   assumption field-caption-class-expression-per-read. Observed values; every literal asserted below is what the BC tier produced.
// Facts: the caption FieldCaption, FieldRef.Caption and a TestPage control give for a table field whose CaptionClass is a literal or an
//   expression with area 2 ('2,0,x', '2,1,x', VAT), 5 ('5,3,', County), 101 (Currency), 1 (Dimension), an area no subscriber resolves, an
//   empty text and '3,'; how often the expression runs per read and with which record (a SingleInstance log counts the calls); whether
//   what the expression changes on Rec stays changed; Sales Line "Inv. Discount Amount" with and without a Sales Header that has
//   Prices Including VAT.
// BC versions: 27, 28, 29

table 86500 "LT QD Cap Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Incl VAT"; Boolean) { }
        field(3; Tag; Text[30]) { }
        field(10; "Lit 2-0"; Decimal) { Caption = 'Cap Lit 2-0'; CaptionClass = '2,0,Inv. Discount Amount'; }
        field(11; "Lit 2-1"; Decimal) { Caption = 'Cap Lit 2-1'; CaptionClass = '2,1,Inv. Discount Amount'; }
        field(12; "Lit 5-3"; Text[30]) { Caption = 'Cap Lit 5-3'; CaptionClass = '5,3,'; }
        field(13; "Lit 5-3 Code"; Text[30]) { Caption = 'Cap Lit 5-3 Code'; CaptionClass = '5,3,QDX'; }
        field(14; "Lit 101-0"; Decimal) { Caption = 'Cap Lit 101-0'; CaptionClass = '101,0,Amount (%1)'; }
        field(15; "Lit 1-1"; Code[20]) { Caption = 'Cap Lit 1-1'; CaptionClass = '1,1,1'; }
        field(20; "Expr 2-0"; Decimal) { Caption = 'Cap Expr 2-0'; CaptionClass = QdCc(20); }
        field(21; "Expr 2-1"; Decimal) { Caption = 'Cap Expr 2-1'; CaptionClass = QdCc(21); }
        field(22; "Expr 5-3"; Text[30]) { Caption = 'Cap Expr 5-3'; CaptionClass = QdCc(22); }
        field(23; "Expr VAT"; Decimal) { Caption = 'Cap Expr VAT'; CaptionClass = QdCc(23); }
        field(24; "Expr Id"; Integer) { Caption = 'Cap Expr Id'; CaptionClass = QdCc(24); }
        field(25; "Expr Empty"; Integer) { Caption = 'Cap Expr Empty'; CaptionClass = QdCc(25); }
        field(26; "Expr 9"; Integer) { Caption = 'Cap Expr 9'; CaptionClass = QdCc(26); }
        field(27; "Expr 2-x"; Integer) { Caption = 'Cap Expr 2-x'; CaptionClass = QdCc(27); }
        field(28; "Expr 3-"; Integer) { Caption = 'Cap Expr 3-'; CaptionClass = QdCc(28); }
        field(29; "Expr 101"; Decimal) { Caption = 'Cap Expr 101'; CaptionClass = QdCc(29); }
        field(30; "Expr 1-1"; Code[20]) { Caption = 'Cap Expr 1-1'; CaptionClass = QdCc(30); }
        field(31; "Expr Touch"; Integer) { Caption = 'Cap Expr Touch'; CaptionClass = QdCc(31); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Touched: Integer;

    procedure QdCc(FieldNumber: Integer): Text[80]
    var
        Log: Codeunit "LT QD Cap Log";
    begin
        Log.Hit(FieldNumber, Id);
        case FieldNumber of
            20:
                exit('2,0,Inv. Discount Amount');
            21:
                exit('2,1,Inv. Discount Amount');
            22:
                exit('5,3,');
            23:
                exit('2,' + Format("Incl VAT", 0, 2) + ',Inv. Discount Amount');
            24:
                exit('3,Id ' + Format(Id) + ' call ' + Format(Log.Total()));
            25:
                exit('');
            26:
                exit('9,x');
            27:
                exit('2,x');
            28:
                exit('3,');
            29:
                exit('101,0,Amount (%1)');
            30:
                exit('1,1,1');
            31:
                begin
                    Touched += 1;
                    Tag := 'touched ' + Format(Touched);
                    exit('3,Touch ' + Format(Touched));
                end;
        end;
    end;

    procedure TouchedCount(): Integer
    begin
        exit(Touched);
    end;
}

page 86501 "LT QD Cap Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QD Cap Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Lit20; Rec."Lit 2-0") { ApplicationArea = All; }
                field(Lit21; Rec."Lit 2-1") { ApplicationArea = All; }
                field(Lit53; Rec."Lit 5-3") { ApplicationArea = All; }
                field(Expr20; Rec."Expr 2-0") { ApplicationArea = All; }
                field(Expr21; Rec."Expr 2-1") { ApplicationArea = All; }
                field(Expr53; Rec."Expr 5-3") { ApplicationArea = All; }
                field(ExprVAT; Rec."Expr VAT") { ApplicationArea = All; }
                field(ExprId; Rec."Expr Id") { ApplicationArea = All; }
                field(ExprEmpty; Rec."Expr Empty") { ApplicationArea = All; }
                field(Expr9; Rec."Expr 9") { ApplicationArea = All; }
                field(Expr2x; Rec."Expr 2-x") { ApplicationArea = All; }
                field(Expr3; Rec."Expr 3-") { ApplicationArea = All; }
                field(PageExpr; Rec.Tag) { ApplicationArea = All; Caption = 'Cap Page Expr'; CaptionClass = PageCc(); }
            }
        }
    }

    local procedure PageCc(): Text
    begin
        exit('2,1,Page Control');
    end;
}

page 86502 "LT QD Cap Sales Lines"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Sales Line";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(No; Rec."No.") { ApplicationArea = All; }
                field(InvDisc; Rec."Inv. Discount Amount") { ApplicationArea = All; }
                field(LineAmount; Rec."Line Amount") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 86503 "LT QD Cap Log"
{
    SingleInstance = true;

    var
        Calls: Text;
        Count: Integer;

    procedure Hit(FieldNumber: Integer; RecId: Integer)
    begin
        Count += 1;
        Calls += Format(FieldNumber) + '@' + Format(RecId) + ';';
    end;

    procedure Total(): Integer
    begin
        exit(Count);
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    procedure Reset()
    begin
        Calls := '';
        Count := 0;
    end;
}

codeunit 86504 "LT QD CaptionClass Areas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT QD Cap Log";

    local procedure Cap(var Observer: Codeunit "Probe Observer"; Name: Text; Caption: Text)
    begin
        Observer.Observe(Name, Caption);
        Observer.Observe(Name + '_calls', Log.Take());
    end;

    [Test]
    procedure Literals_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 1;
        Cap(Observer, 'lit20', R.FieldCaption("Lit 2-0"));
        Cap(Observer, 'lit21', R.FieldCaption("Lit 2-1"));
        Cap(Observer, 'lit53', R.FieldCaption("Lit 5-3"));
        Cap(Observer, 'lit53code', R.FieldCaption("Lit 5-3 Code"));
        Cap(Observer, 'lit101', R.FieldCaption("Lit 101-0"));
        Cap(Observer, 'lit11', R.FieldCaption("Lit 1-1"));
        Observer.Finish();
    end;

    [Test]
    procedure Expressions_FieldCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 1;
        Cap(Observer, 'expr20', R.FieldCaption("Expr 2-0"));
        Cap(Observer, 'expr21', R.FieldCaption("Expr 2-1"));
        Cap(Observer, 'expr53', R.FieldCaption("Expr 5-3"));
        Cap(Observer, 'exprEmpty', R.FieldCaption("Expr Empty"));
        Cap(Observer, 'expr9', R.FieldCaption("Expr 9"));
        Cap(Observer, 'expr2x', R.FieldCaption("Expr 2-x"));
        Cap(Observer, 'expr3', R.FieldCaption("Expr 3-"));
        Cap(Observer, 'expr101', R.FieldCaption("Expr 101"));
        Cap(Observer, 'expr11', R.FieldCaption("Expr 1-1"));
        Observer.Finish();
    end;

    [Test]
    procedure Expression_VatSwitch_SameRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 1;
        R."Incl VAT" := false;
        Cap(Observer, 'excl', R.FieldCaption("Expr VAT"));
        R."Incl VAT" := true;
        Cap(Observer, 'incl', R.FieldCaption("Expr VAT"));
        R."Incl VAT" := false;
        Cap(Observer, 'excl_again', R.FieldCaption("Expr VAT"));
        Observer.Finish();
    end;

    [Test]
    procedure Expression_PerRead_CallCount()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        R2: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 1;
        R2.Id := 2;
        Cap(Observer, 'r1_first', R.FieldCaption("Expr Id"));
        Cap(Observer, 'r1_second', R.FieldCaption("Expr Id"));
        Cap(Observer, 'r2', R2.FieldCaption("Expr Id"));
        Cap(Observer, 'r1_fieldname', R.FieldName("Expr Id"));
        Observer.Observe('total', Format(Log.Total()));
        Observer.Finish();
    end;

    [Test]
    procedure Expression_ChangesRec()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
    begin
        Log.Reset();
        R.Id := 4;
        R.Tag := 'before';
        Cap(Observer, 'first', R.FieldCaption("Expr Touch"));
        Observer.Observe('tag_after_first', R.Tag);
        Observer.Observe('touched_after_first', Format(R.TouchedCount()));
        Cap(Observer, 'second', R.FieldCaption("Expr Touch"));
        Observer.Observe('tag_after_second', R.Tag);
        Observer.Observe('touched_after_second', Format(R.TouchedCount()));
        Observer.Finish();
    end;

    [Test]
    procedure Expressions_FieldRefCaption()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        Ref: RecordRef;
        Fresh: RecordRef;
    begin
        Log.Reset();
        R.Id := 7;
        R."Incl VAT" := true;
        Ref.GetTable(R);
        Cap(Observer, 'ref_expr20', Ref.Field(20).Caption());
        Cap(Observer, 'ref_expr21', Ref.Field(21).Caption());
        Cap(Observer, 'ref_expr53', Ref.Field(22).Caption());
        Cap(Observer, 'ref_exprVAT', Ref.Field(23).Caption());
        Cap(Observer, 'ref_exprId', Ref.Field(24).Caption());
        Cap(Observer, 'ref_exprEmpty', Ref.Field(25).Caption());
        Cap(Observer, 'ref_lit20', Ref.Field(10).Caption());
        Cap(Observer, 'ref_lit53', Ref.Field(12).Caption());
        Fresh.Open(Database::"LT QD Cap Row");
        Cap(Observer, 'fresh_exprId', Fresh.Field(24).Caption());
        Cap(Observer, 'fresh_exprVAT', Fresh.Field(23).Caption());
        Observer.Finish();
    end;

    [Test]
    procedure Page_ControlCaptions()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT QD Cap Row";
        P: TestPage "LT QD Cap Card";
    begin
        R.DeleteAll();
        R.Id := 3;
        R."Incl VAT" := true;
        R.Insert();
        Log.Reset();
        P.OpenView();
        Observer.Observe('open_calls', Log.Take());
        Cap(Observer, 'lit20', P.Lit20.Caption());
        Cap(Observer, 'lit21', P.Lit21.Caption());
        Cap(Observer, 'lit53', P.Lit53.Caption());
        Cap(Observer, 'expr20', P.Expr20.Caption());
        Cap(Observer, 'expr21', P.Expr21.Caption());
        Cap(Observer, 'expr53', P.Expr53.Caption());
        Cap(Observer, 'exprVAT', P.ExprVAT.Caption());
        Cap(Observer, 'exprId', P.ExprId.Caption());
        Cap(Observer, 'exprId_again', P.ExprId.Caption());
        Cap(Observer, 'exprEmpty', P.ExprEmpty.Caption());
        Cap(Observer, 'expr9', P.Expr9.Caption());
        Cap(Observer, 'expr2x', P.Expr2x.Caption());
        Cap(Observer, 'expr3', P.Expr3.Caption());
        Cap(Observer, 'pageExpr', P.PageExpr.Caption());
        P.Close();
        Observer.Observe('close_calls', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SalesLine_InvDiscountAmount_NoHeader()
    var
        Observer: Codeunit "Probe Observer";
        SalesLine: Record "Sales Line";
        Ref: RecordRef;
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'QD-NOHEADER';
        Observer.Observe('invdisc', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Observe('lineamount', SalesLine.FieldCaption("Line Amount"));
        Observer.Observe('no', SalesLine.FieldCaption("No."));
        Ref.GetTable(SalesLine);
        Observer.Observe('ref_invdisc', Ref.Field(SalesLine.FieldNo("Inv. Discount Amount")).Caption());
        Observer.Finish();
    end;

    [Test]
    procedure SalesLine_InvDiscountAmount_PricesInclVat()
    var
        Observer: Codeunit "Probe Observer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Ref: RecordRef;
        P: TestPage "LT QD Cap Sales Lines";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := 'QD-INCLVAT';
        SalesHeader."Prices Including VAT" := true;
        SalesHeader.Insert(false);
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := 'QD-INCLVAT';
        SalesLine."Line No." := 10000;
        SalesLine.Insert(false);
        Observer.Observe('invdisc', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Observe('lineamount', SalesLine.FieldCaption("Line Amount"));
        Observer.Observe('no', SalesLine.FieldCaption("No."));
        Ref.GetTable(SalesLine);
        Observer.Observe('ref_invdisc', Ref.Field(SalesLine.FieldNo("Inv. Discount Amount")).Caption());
        P.OpenView();
        P.Filter.SetFilter("Document No.", 'QD-INCLVAT');
        P.First();
        Observer.Observe('page_invdisc', P.InvDisc.Caption());
        Observer.Observe('page_lineamount', P.LineAmount.Caption());
        Observer.Observe('page_no', P.No.Caption());
        P.Close();
        SalesLine."Document No." := 'QD-OTHER';
        Observer.Observe('other_doc_invdisc', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Finish();
    end;
}
