// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-transactiontype-property
// Scope: fixture reports used by "Test TxModel Report Run" (60040)
// Fixture table: ALT Base (60007)
//
// Three ProcessingOnly reports with the same body — one "ALT Base" row, keyed by a number the
// caller passes in, written from OnAfterGetRecord — that differ only in the two properties
// that decide whether Report.Run enters a transaction world: whether a request page is used,
// and whether the declared TransactionType differs from the session's.
//
//   60026 has a request page (UseRequestPage defaults to true) and the default TransactionType.
//   60027 has no request page and declares TransactionType = Update.
//   60028 has no request page and the default TransactionType — the report that does NOT
//         enter a transaction world, and so the control for the other two.

report 60026 "TxRpt ReqPage Marker"
{
    Caption = 'TxRpt ReqPage Marker';
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
                ALTBase.Init();
                ALTBase."Entry No." := MarkerNo;
                ALTBase.Name := 'txrpt-reqpage-marker';
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

report 60027 "TxRpt Update Marker"
{
    Caption = 'TxRpt Update Marker';
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
                ALTBase.Init();
                ALTBase."Entry No." := MarkerNo;
                ALTBase.Name := 'txrpt-update-marker';
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

report 60028 "TxRpt Plain Marker"
{
    Caption = 'TxRpt Plain Marker';
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
                ALTBase.Init();
                ALTBase."Entry No." := MarkerNo;
                ALTBase.Name := 'txrpt-plain-marker';
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
