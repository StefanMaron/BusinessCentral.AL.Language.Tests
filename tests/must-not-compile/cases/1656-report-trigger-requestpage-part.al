// @expect AL0161 | 'Part ChPart: "MNC CH Part 1656"' is inaccessible due to its protection level
// A report trigger (OnPreReport) calls RequestOptionsPage.<Part>.Page.<Procedure>() for a part of its request page. The part is not reachable from
// report code; the same call from the request page OnOpenPage compiles (tests/al-language/report/lt-ch-report-leads/ChReportPart.al). Corpus issue 667 item 117.
table 51656 "MNC CH T1656"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

page 51657 "MNC CH Part 1656"
{
    PageType = ListPart;
    SourceTable = "MNC CH T1656";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

report 51658 "MNC CH R1656"
{
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                part(ChPart; "MNC CH Part 1656")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        Message(RequestOptionsPage.ChPart.Page.Ping());
    end;
}
