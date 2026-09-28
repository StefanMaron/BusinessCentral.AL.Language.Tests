// A page and a report in the DEPENDENCY app, so that the main app sees both as precompiled,
// plus this app's own extensions of them. The main app's tests (codeunit 67670,
// tests/al-language/handlers/TestPageExtensionModifyCaption_Tests.al) read the captions a
// modify() gives these controls through TestPage / TestRequestPage.
//
// Page 61020's controls:
//   FxTextCtl  - modified only by the main app's pageextension 67671 (Caption).
//   FxOptCtl   - modified only by the main app's pageextension 67671 (Caption and OptionCaption).
//   FxBothCtl  - modified by pageextension 61021 below AND by the main app's pageextension 67671,
//                to different Captions: which one BC applies is what the test measures.
//   FxBoth2Ctl - the same, where the main app's pageextension (60941) has the LOWER object id.
//   FxOwnCtl   - modified only by pageextension 61021 below.
// Report 61022's request-page controls are modified only by reportextension 61023 below.
//
// Written by agent stma-auto-6 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4928.

page 61020 "ALT Modify Caption Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(FxTextCtl; FxText) { ApplicationArea = All; Caption = 'Fixture Text'; }
            field(FxOptCtl; FxOpt) { ApplicationArea = All; Caption = 'Fixture Option'; OptionCaption = 'Red,Green'; }
            field(FxBothCtl; FxBoth) { ApplicationArea = All; Caption = 'Fixture Both'; }
            field(FxBoth2Ctl; FxBoth2) { ApplicationArea = All; Caption = 'Fixture Both2'; }
            field(FxOwnCtl; FxOwn) { ApplicationArea = All; Caption = 'Fixture Own'; }
        }
    }

    var
        FxText: Text[30];
        FxOpt: Option Red,Green;
        FxBoth: Text[30];
        FxBoth2: Text[30];
        FxOwn: Text[30];
}

pageextension 61021 "ALT Modify Caption Page Ext" extends "ALT Modify Caption Page"
{
    layout
    {
        modify(FxBothCtl) { Caption = 'Fixture Ext Both'; }
        modify(FxBoth2Ctl) { Caption = 'Fixture Ext Both2'; }
        modify(FxOwnCtl) { Caption = 'Fixture Ext Own'; }
    }
}

report 61022 "ALT Modify Caption Report"
{
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ApplicationArea = All;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FxReqTextCtl; FxReqText) { ApplicationArea = All; Caption = 'Fixture Request Text'; }
                field(FxReqOptCtl; FxReqOpt) { ApplicationArea = All; Caption = 'Fixture Request Option'; OptionCaption = 'Low,High'; }
            }
        }
    }

    var
        FxReqText: Text[30];
        FxReqOpt: Option Low,High;
}

reportextension 61023 "ALT Modify Caption Report Ext" extends "ALT Modify Caption Report"
{
    requestpage
    {
        layout
        {
            modify(FxReqTextCtl) { Caption = 'Fixture Ext Request Text'; }
            modify(FxReqOptCtl) { Caption = 'Fixture Ext Request Option'; OptionCaption = 'Lower,Higher'; }
        }
    }
}
