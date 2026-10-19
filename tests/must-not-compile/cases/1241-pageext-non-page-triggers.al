// @expect AL0162 | 'OnRun' is not a valid trigger for this object type.
// @expect AL0162 | 'OnInsert' is not a valid trigger for this object type.
// @expect AL0162 | 'OnValidate' is not a valid trigger for this object type.
// @expect AL0162 | 'OnAction' is not a valid trigger for this object type.
// @expect AL0162 | 'OnPreReport' is not a valid trigger for this object type.
// @expect AL0162 | 'OnBeforeOpen' is not a valid trigger for this object type.
// @expect AL0162 | 'OnFoo' is not a valid trigger for this object type.
// A page extension declares triggers that are not page triggers: a codeunit trigger (OnRun), a table trigger (OnInsert), a field trigger
// (OnValidate), an action trigger (OnAction), a report trigger (OnPreReport), a query trigger (OnBeforeOpen) and an invented name (OnFoo).
// Each gets AL0162, the code that OnInit, OnFindRecord and OnNextRecord get (cases 0004, 0017, 0018). (7 diagnostics)
table 50000 "MNC BB Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50001 "MNC BB Page"
{
    SourceTable = "MNC BB Table";
    layout { area(Content) { field(Id; Rec.Id) { } } }
}
pageextension 50002 "MNC BB Page Ext" extends "MNC BB Page"
{
    trigger OnRun()
    begin
    end;

    trigger OnInsert()
    begin
    end;

    trigger OnValidate()
    begin
    end;

    trigger OnAction()
    begin
    end;

    trigger OnPreReport()
    begin
    end;

    trigger OnBeforeOpen()
    begin
    end;

    trigger OnFoo()
    begin
    end;
}
