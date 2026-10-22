// @expect AL0132 | 'TestPage MNC DH Page 1864' does not contain a definition for 'Sp'
// @expect AL0132 | 'TestPage MNC DH Page 1864' does not contain a definition for 'Up'
// @expect AL0132 | 'TestPage MNC DH Page 1864' does not contain a definition for 'Ca'
// @expect AL0132 | 'TestPage MNC DH Page 1864' does not contain a definition for 'V'
// @expect AL0132 | 'TestPage MNC DH Card 1864' does not contain a definition for 'Uc'
// Corpus issue 663 item 1: a TestPage cannot reach a system part, file upload action, custom action, view or user control. These carry
// ObsoleteState = Pending here (which compiles, misc/lt-dh-obsolete-props and pages/lt-x-obsolete-pending/XObsoletePending.al), but the
// TestPage has no member for them at all (one AL0132 each).
controladdin "MNC DH AddIn 1864" { RequestedHeight = 100; }
table 51864 "MNC DH T 1864" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 51865 "MNC DH Page 1864"
{
    PageType = List;
    SourceTable = "MNC DH T 1864";
    layout
    {
        area(Content) { repeater(R) { field(Id; Rec.Id) { } } }
        area(FactBoxes) { systempart(Sp; Links) { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = 't'; } }
    }
    actions
    {
        area(Processing)
        {
            fileuploadaction(Up) { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = 't'; trigger OnAction(Files: List of [FileUpload]) begin end; }
            customaction(Ca) { CustomActionType = Flow; FlowId = '11111111-1111-1111-1111-111111111111'; ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = 't'; }
        }
    }
    views { view(V) { Caption = 'v'; Filters = where(Id = const(1)); ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = 't'; } }
}
page 51866 "MNC DH Card 1864"
{
    PageType = Card;
    SourceTable = "MNC DH T 1864";
    layout { area(Content) { usercontrol(Uc; "MNC DH AddIn 1864") { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = 't'; } } }
}
codeunit 51867 "MNC DH Use 1864"
{
    Subtype = Test;
    [Test] procedure SysPart() var Pg: TestPage "MNC DH Page 1864"; begin Pg.OpenView(); if Pg.Sp.Visible() then; end;
    [Test] procedure Upload() var Pg: TestPage "MNC DH Page 1864"; begin Pg.OpenView(); Pg.Up.Invoke(); end;
    [Test] procedure Custom() var Pg: TestPage "MNC DH Page 1864"; begin Pg.OpenView(); Pg.Ca.Invoke(); end;
    [Test] procedure View() var Pg: TestPage "MNC DH Page 1864"; begin Pg.OpenView(); if Pg.V.Visible() then; end;
    [Test] procedure UserControl() var Pg: TestPage "MNC DH Card 1864"; begin Pg.OpenView(); if Pg.Uc.Visible() then; end;
}
