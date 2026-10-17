// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-styleexpr-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71886, page 71887 and test codeunit 71888
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the PageStyle enum: Format(PageStyle::X), Format(PageStyle::X, 0, 2) and Format(PageStyle::X, 0, 1) for every member (PageStyle is an option-like type: AsInteger does not exist); the text assigned to a
//   StyleExpr variable on a page and the style text the page holds.
// BC versions: 27, 28, 29
table 71886 "LT PS Row"
{
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

page 71887 "LT PS List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT PS Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleText;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleText;
                }
            }
        }
    }

    var
        StyleText: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Id of
            1:
                StyleText := Format(PageStyle::Strong);
            2:
                StyleText := Format(PageStyle::Unfavorable);
            else
                StyleText := Format(PageStyle::None);
        end;
    end;

    procedure StyleOf(): Text
    begin
        exit(StyleText);
    end;
}

codeunit 71888 "LT PageStyle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageStyle_Format_AllMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format_None', Format(PageStyle::None));
        Observer.Observe('format_Standard', Format(PageStyle::Standard));
        Observer.Observe('format_StandardAccent', Format(PageStyle::StandardAccent));
        Observer.Observe('format_Strong', Format(PageStyle::Strong));
        Observer.Observe('format_StrongAccent', Format(PageStyle::StrongAccent));
        Observer.Observe('format_Attention', Format(PageStyle::Attention));
        Observer.Observe('format_AttentionAccent', Format(PageStyle::AttentionAccent));
        Observer.Observe('format_Favorable', Format(PageStyle::Favorable));
        Observer.Observe('format_Unfavorable', Format(PageStyle::Unfavorable));
        Observer.Observe('format_Ambiguous', Format(PageStyle::Ambiguous));
        Observer.Observe('format_Subordinate', Format(PageStyle::Subordinate));
        Observer.Finish();
    end;

    [Test]
    procedure PageStyle_FormatNumber2_AllMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format2_None', Format(PageStyle::None, 0, 2));
        Observer.Observe('format2_Standard', Format(PageStyle::Standard, 0, 2));
        Observer.Observe('format2_StandardAccent', Format(PageStyle::StandardAccent, 0, 2));
        Observer.Observe('format2_Strong', Format(PageStyle::Strong, 0, 2));
        Observer.Observe('format2_StrongAccent', Format(PageStyle::StrongAccent, 0, 2));
        Observer.Observe('format2_Attention', Format(PageStyle::Attention, 0, 2));
        Observer.Observe('format2_AttentionAccent', Format(PageStyle::AttentionAccent, 0, 2));
        Observer.Observe('format2_Favorable', Format(PageStyle::Favorable, 0, 2));
        Observer.Observe('format2_Unfavorable', Format(PageStyle::Unfavorable, 0, 2));
        Observer.Observe('format2_Ambiguous', Format(PageStyle::Ambiguous, 0, 2));
        Observer.Observe('format2_Subordinate', Format(PageStyle::Subordinate, 0, 2));
        Observer.Finish();
    end;


    [Test]
    procedure PageStyle_FormatNumber1_AllMembers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format1_None', Format(PageStyle::None, 0, 1));
        Observer.Observe('format1_Standard', Format(PageStyle::Standard, 0, 1));
        Observer.Observe('format1_StandardAccent', Format(PageStyle::StandardAccent, 0, 1));
        Observer.Observe('format1_Strong', Format(PageStyle::Strong, 0, 1));
        Observer.Observe('format1_StrongAccent', Format(PageStyle::StrongAccent, 0, 1));
        Observer.Observe('format1_Attention', Format(PageStyle::Attention, 0, 1));
        Observer.Observe('format1_AttentionAccent', Format(PageStyle::AttentionAccent, 0, 1));
        Observer.Observe('format1_Favorable', Format(PageStyle::Favorable, 0, 1));
        Observer.Observe('format1_Unfavorable', Format(PageStyle::Unfavorable, 0, 1));
        Observer.Observe('format1_Ambiguous', Format(PageStyle::Ambiguous, 0, 1));
        Observer.Observe('format1_Subordinate', Format(PageStyle::Subordinate, 0, 1));
        Observer.Finish();
    end;

    [Test]
    procedure PageStyle_FormatIntoTextAndBack()
    var
        Observer: Codeunit "Probe Observer";
        Style: PageStyle;
        Txt: Text;
        Ok: Boolean;
    begin
        Txt := Format(PageStyle::AttentionAccent);
        Observer.Observe('text', Txt);
        Ok := Evaluate(Style, Txt);
        Observer.Observe('evaluate_ok', Format(Ok));
        Observer.Observe('evaluate_back_format1', Format(Style, 0, 1));
        Ok := Evaluate(Style, 'strong');
        Observer.Observe('evaluate_lowercase_ok', Format(Ok));
        Observer.Observe('evaluate_lowercase_format1', Format(Style, 0, 1));
        Style := PageStyle::Favorable;
        Observer.Observe('default_after_assign', Format(Style));
        Clear(Style);
        Observer.Observe('cleared', Format(Style));
        Observer.Finish();
    end;

    [Test]
    procedure PageStyle_StyleExpr_PageHoldsText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PS Row";
        PageLst: TestPage "LT PS List";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'strong';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'unfavorable';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'none';
        Row.Insert();
        PageLst.OpenView();
        PageLst.First();
        Observer.Observe('row1_id', PageLst.Id.Value());
        PageLst.Next();
        Observer.Observe('row2_id', PageLst.Id.Value());
        PageLst.Close();
        Row.DeleteAll();
        Observer.Finish();
    end;
}
