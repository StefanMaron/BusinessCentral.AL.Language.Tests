// @expect AL0132 | '__MissingTypeSymbol__' does not contain a definition for 'Reset'
// @depends AL Language XApp A,AL Language XApp B
// Cross-app (corpus #668 item 95): page "LT BW XB Master Card" of cross-app fixture B has a protected variable TheBlah whose type,
// Record "ALT XApp Mut Probe", is a table of the AL Internals Test Fixture app. This app depends on cross-app fixtures A and B only, like
// cross-app fixture C. Extending the page compiles and runs (tableextension/lt-bw-cross-app/BwCrossAppTests.al); using the variable does not.
// Needs the compiled fixture app and cross-app fixtures A and B in the symbols folder (CONTRIBUTING.md, "Multi-app fixtures").
pageextension 51580 "MNC BW Master Card Use" extends "LT BW XB Master Card"
{
    trigger OnOpenPage()
    begin
        TheBlah.Reset();
    end;
}
