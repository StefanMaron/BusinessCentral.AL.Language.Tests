// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-transactiontype-property
// Scope: fixture reports used by "Test TxModel Report Exec" (60029)
// Fixture table: ALT Base (60007)
//
// Three ProcessingOnly reports with the same body — one "ALT Base" row, keyed by a number the
// caller passes in, written from OnAfterGetRecord — that differ only in the two properties that
// decide whether a report run enters a transaction world: whether a request page is used, and
// whether the declared TransactionType differs from the session's.
//
//   60029 has a request page (UseRequestPage defaults to true) and the default TransactionType.
//   60030 has no request page and declares TransactionType = Update.
//   60031 has no request page and the default TransactionType.
//
// A static Report.Execute / Report.RunRequestPage builds its own instance, so SetMarker never
// reaches it; each report then writes its own fixed default key (60029990-60029992) instead of 0,
// so a static arm cannot collide with a row another codeunit wrote at key 0.

report 60029 "TxExec ReqPage Marker"
{
    Caption = 'TxExec ReqPage Marker';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                ALTBase: Record "ALT Base";
            begin
                if MarkerNo = 0 then
                    MarkerNo := 60029990;
                ALTBase.Init();
                ALTBase."Entry No." := MarkerNo;
                ALTBase.Name := 'txexec-reqpage-marker';
                ALTBase.Insert();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(EchoText; EchoText)
                    {
                        ApplicationArea = All;
                        Caption = 'Echo Text';
                        ToolTip = 'Unused; present so the report has a real request page.';
                    }
                }
            }
        }
    }

    var
        MarkerNo: Integer;
        EchoText: Text[30];

    procedure SetMarker(NewMarkerNo: Integer)
    begin
        MarkerNo := NewMarkerNo;
    end;
}

report 60030 "TxExec Update Marker"
{
    Caption = 'TxExec Update Marker';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;
    TransactionType = Update;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                ALTBase: Record "ALT Base";
            begin
                if MarkerNo = 0 then
                    MarkerNo := 60029991;
                ALTBase.Init();
                ALTBase."Entry No." := MarkerNo;
                ALTBase.Name := 'txexec-update-marker';
                ALTBase.Insert();
            end;
        }
    }

    var
        MarkerNo: Integer;

    procedure SetMarker(NewMarkerNo: Integer)
    begin
        MarkerNo := NewMarkerNo;
    end;
}

report 60031 "TxExec Plain Marker"
{
    Caption = 'TxExec Plain Marker';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                ALTBase: Record "ALT Base";
            begin
                if MarkerNo = 0 then
                    MarkerNo := 60029992;
                ALTBase.Init();
                ALTBase."Entry No." := MarkerNo;
                ALTBase.Name := 'txexec-plain-marker';
                ALTBase.Insert();
            end;
        }
    }

    var
        MarkerNo: Integer;

    procedure SetMarker(NewMarkerNo: Integer)
    begin
        MarkerNo := NewMarkerNo;
    end;
}
