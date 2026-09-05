// A List over "ALT Keyed" whose SourceTableView declares all three clauses AL allows there:
// sorting(...) on a key the table really has, order(descending), and a where(...) carrying
// both a filter(...) and a const(...) entry.
//
// The OnOpenPage trigger logs what the page's own record saw at open time, in filter group 0
// and in filter group 2, into "ALT Trigger Log" — a TestPage exposes controls and actions
// only, so an observation of the record's filter groups has to travel through a table.
page 60821 "ALT Source Table View List"
{
    Caption = 'ALT Source Table View List';
    PageType = List;
    SourceTable = "ALT Keyed";
    Editable = false;
    SourceTableView = sorting(Amount)
                      order(descending)
                      where("Entry No." = filter(1 | 2 | 3), Status = const(Active));

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog."TriggerName" := 'OnOpenPage';
        // Filter group 0 is the user's own filter pane; a view filter must not appear here.
        TrigLog."OldValue" := CopyStr(Rec.GetFilter(Status), 1, 100);
        Rec.FilterGroup(2);
        // Filter group 2 is where the platform puts a page's SourceTableView filters.
        TrigLog."NewValue" := CopyStr(Rec.GetFilter(Status), 1, 100);
        Rec.FilterGroup(0);
        TrigLog."LoggedAt" := CurrentDateTime();
        TrigLog.Insert();
    end;
}
