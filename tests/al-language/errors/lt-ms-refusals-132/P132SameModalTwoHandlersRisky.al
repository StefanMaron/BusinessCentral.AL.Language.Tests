// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own page 73730, log 73731 (used only by test codeunit 73729). RISKY: BC may fail a test whose second handler for the same page is never called, or refuse the declaration.
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 73730 "LT P132 Same Modal"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(TxtS; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[20];
}

codeunit 73731 "LT P132 Same Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 73729 "LT P132 Same Modal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P132 Same Log";

    [ModalPageHandler]
    procedure FirstHandler(var P: TestPage "LT P132 Same Modal")
    begin
        Log.Add('first');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SecondHandler(var P: TestPage "LT P132 Same Modal")
    begin
        Log.Add('second');
        P.OK().Invoke();
    end;
}
