// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-addin-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: a control add-in with a procedure and an event, hosted by a usercontrol of a page. A field trigger calls the add-in procedure; the test sets the field on a TestPage (there is no client, so no add-in script runs). The compile error for an unknown add-in procedure is must-not-compile case 0991. Settles #626 item 16.
// BC versions: 27, 28, 29

controladdin "LT AC Addin"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Say(Message: Text);
    procedure Count(Value: Integer; Flag: Boolean);
    event Ready();
    event Answered(Answer: Text);
}

table 77540 "LT AC Addin Row"
{
    DataClassification = SystemMetadata;

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

page 77540 "LT AC Addin Card"
{
    PageType = Card;
    SourceTable = "LT AC Addin Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    CurrPage.Ctl.Say(Rec.Name);
                    CurrPage.Ctl.Count(1, true);
                    AddinCalls += 1;
                end;
            }
            usercontrol(Ctl; "LT AC Addin")
            {
                ApplicationArea = All;

                trigger Ready()
                begin
                    ReadyCalls += 1;
                end;

                trigger Answered(Answer: Text)
                begin
                    LastAnswer := Answer;
                end;
            }
        }
    }

    var
        AddinCalls: Integer;
        ReadyCalls: Integer;
        LastAnswer: Text;
}

codeunit 77540 "LT AC ControlAddIn"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_ControlAddIn_ProcedureCallFromFieldTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Addin Row";
        TP: TestPage "LT AC Addin Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'start';
        Row.Insert();
        TP.OpenEdit();
        Observer.Observe('opened', TP.NameF.Value());
        asserterror TP.NameF.SetValue('changed');
        Observer.ObserveError('set_name');
        Observer.Expect('opened', 'start');
        Observer.Expect('set_name|text', 'The control add-in on control Ctl on page LT AC Addin Card has not been instantiated.');
        Observer.Expect('set_name|code', 'NSValidationFailed:DotNetControlAddInNotCreated');
        Observer.Verify();
    end;

}
