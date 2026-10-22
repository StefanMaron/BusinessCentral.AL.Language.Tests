// @expect AL0196 | The call is ambiguous between the method 'BwSame()' defined in Table 'LT BW XA Base' by the extension 'AL Language XApp A by AL Language (1.0.0.0)' and the method 'BwSame()' defined in TableExtension 'LT BW XB Base Same Ext' by the extension 'AL Language XApp B by Zulu Probe Publisher (1.0.0.0)'.
// @expect AL0196 | The call is ambiguous between the method 'BwSame()' defined in Table 'LT BW XA Base' by the extension 'AL Language XApp A by AL Language (1.0.0.0)' and the method 'BwSame()' defined in TableExtension 'LT BW XB Base Same Ext' by the extension 'AL Language XApp B by Zulu Probe Publisher (1.0.0.0)'.
// @expect AL0196 | The call is ambiguous between the method 'BwCaseName()' defined in Table 'LT BW XA Base' by the extension 'AL Language XApp A by AL Language (1.0.0.0)' and the method 'bwcasename()' defined in TableExtension 'LT BW XB Base Same Ext' by the extension 'AL Language XApp B by Zulu Probe Publisher (1.0.0.0)'.
// @depends AL Language XApp A,AL Language XApp B
// Cross-app, writer QY (al-runtime-rs backlog "PROBES from multiapp-runtime", item 3): table "LT BW XA Base" of cross-app fixture A and table
// extension "LT BW XB Base Same Ext" of cross-app fixture B both declare BwSame() (and BwCaseName() / bwcasename()). A table extension of a
// third app calls them bare (BwSame()) and through Rec (Rec.BwSame()): AL0196, as the call through a record variable in must-not-compile 1581.
// The same calls from a third table extension inside app B compile: tableextension/lt-bw-cross-app/BwCrossAppTests.al.
// Needs the compiled fixture app and cross-app fixtures A and B in the symbols folder (CONTRIBUTING.md, "Multi-app fixtures").
tableextension 52075 "MNC QY Base Third App Ext" extends "LT BW XA Base"
{
    procedure QyCallSameBare(): Text
    begin
        exit(BwSame());
    end;

    procedure QyCallSameRec(): Text
    begin
        exit(Rec.BwSame());
    end;

    procedure QyCallCaseNameBare(): Text
    begin
        exit(BwCaseName());
    end;
}
