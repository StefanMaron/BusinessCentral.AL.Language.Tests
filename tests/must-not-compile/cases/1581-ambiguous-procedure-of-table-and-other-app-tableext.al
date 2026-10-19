// @expect AL0196 | The call is ambiguous between the method 'BwSame()' defined in Table 'LT BW XA Base' by the extension 'AL Language XApp A by AL Language (1.0.0.0)' and the method 'BwSame()' defined in TableExtension 'LT BW XB Base Same Ext' by the extension 'AL Language XApp B by Zulu Probe Publisher (1.0.0.0)'.
// @expect AL0196 | The call is ambiguous between the method 'BwCaseName()' defined in Table 'LT BW XA Base' by the extension 'AL Language XApp A by AL Language (1.0.0.0)' and the method 'bwcasename()' defined in TableExtension 'LT BW XB Base Same Ext' by the extension 'AL Language XApp B by Zulu Probe Publisher (1.0.0.0)'.
// @depends AL Language XApp A,AL Language XApp B
// Cross-app (corpus #668 item 87): table "LT BW XA Base" of cross-app fixture A declares BwSame() and BwCaseName(); the table extension
// "LT BW XB Base Same Ext" of cross-app fixture B declares BwSame() and bwcasename() (B compiles, with warning AL0523 "... already defines a
// method called ... This warning will become an error in a future release."). A third app that calls them gets AL0196. Calls from inside
// app A and app B compile: tableextension/lt-bw-cross-app/BwCrossAppTests.al.
// Needs the compiled fixture app and cross-app fixtures A and B in the symbols folder (CONTRIBUTING.md, "Multi-app fixtures").
codeunit 51581 "MNC BW Ambiguous Call"
{
    procedure CallBoth(): Text
    var
        Base: Record "LT BW XA Base";
    begin
        exit(Base.BwSame() + Base.BwCaseName());
    end;
}
