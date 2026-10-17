// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own fixtures declared in this file (table 67161, codeunit 67162, xmlports 67163 and 67164)
// Probe: Xmlport.Run(Id) with one argument and Xmlport.Run(Id, RequestWindow, Import) on an export xmlport that has no destination, once with
// UseRequestPage = false and once with the default (true): does the run succeed, does the tableelement visit its rows, and is a request page opened
// (the outcome of a run without a handler tells). Complements XmlportRunExport.al (Run with three arguments and no request page).
// Object ids 67161 - 67165.

table 67161 "LT XR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67162 "LT XR Log"
{
    SingleInstance = true;

    var
        Count: Integer;

    procedure Hit()
    begin
        Count += 1;
    end;

    procedure Hits(): Integer
    begin
        exit(Count);
    end;

    procedure Reset()
    begin
        Count := 0;
    end;
}

xmlport 67163 "LT XR No Request Page"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT XR Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT XR Log";
                begin
                    Log.Hit();
                end;
            }
        }
    }
}

xmlport 67164 "LT XR With Request Page"
{
    Format = Xml;
    Direction = Export;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "LT XR Row")
            {
                fieldelement(Id; T.Id) { }
                fieldelement(Txt; T.Txt) { }

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT XR Log";
                begin
                    Log.Hit();
                end;
            }
        }
    }
}

codeunit 67165 "LT XR Run Request Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT XR Log";

    local procedure Seed()
    var
        Row: Record "LT XR Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 3 do begin
            Row.Init();
            Row.Id := Index;
            Row.Txt := 'row ' + Format(Index);
            Row.Insert();
        end;
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOneArgument(Id: Integer)
    begin
        Xmlport.Run(Id);
    end;

    [TryFunction]
    local procedure TryThreeArguments(Id: Integer; Window: Boolean; ImportFlag: Boolean)
    begin
        Xmlport.Run(Id, Window, ImportFlag);
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok|hits=' + Format(Log.Hits()));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|hits=' + Format(Log.Hits()));
    end;

    [Test]
    procedure Run_NoRequestPage_OneArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('one_argument', Outcome(TryOneArgument(Xmlport::"LT XR No Request Page")));
        Observer.Finish();
    end;

    [Test]
    procedure Run_NoRequestPage_WindowTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('window_true', Outcome(TryThreeArguments(Xmlport::"LT XR No Request Page", true, false)));
        Observer.Finish();
    end;

    [Test]
    procedure Run_NoRequestPage_WindowFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('window_false', Outcome(TryThreeArguments(Xmlport::"LT XR No Request Page", false, false)));
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRequestPage_WindowFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('window_false', Outcome(TryThreeArguments(Xmlport::"LT XR With Request Page", false, false)));
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRequestPage_OneArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('one_argument', Outcome(TryOneArgument(Xmlport::"LT XR With Request Page")));
        Observer.Finish();
    end;

    [Test]
    procedure Run_WithRequestPage_WindowTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ClearLastError();
        Observer.Observe('window_true', Outcome(TryThreeArguments(Xmlport::"LT XR With Request Page", true, false)));
        Observer.Finish();
    end;
}
