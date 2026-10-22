// Cross-app fixture C extends cross-app fixture B's page 61110, whose protected variable TheBlah has a type from the AL Internals Test
// Fixture app. This app depends on cross-app fixtures A and B only, not on the fixture app (corpus #668 item 95; microsoft/AL issue 6637
// said the publish of such an extension failed, fixed in runtime 27.0). Test: tests/al-language/tableextension/lt-bw-cross-app/.
pageextension 61120 "LT BW XC Master Card Ext" extends "LT BW XB Master Card"
{
    layout
    {
        addlast(Content)
        {
            field(BwXcMarker; MarkerText) { Caption = 'C Marker'; ApplicationArea = All; }
        }
    }

    var
        MarkerText: Text;

    trigger OnOpenPage()
    begin
        MarkerText := 'extension of app C';
    end;
}
