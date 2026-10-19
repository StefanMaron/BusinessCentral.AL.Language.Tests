// @expect AL0161 | 'ShowAssemblyDocument()' is inaccessible due to its protection level
// @expect AL0161 | 'ShowAssemblyDocument()' is inaccessible due to its protection level
// @expect AL0161 | 'ShowAssemblyDocument()' is inaccessible due to its protection level
// @expect AL0161 | 'ShowAssemblyDocument()' is inaccessible due to its protection level
// @expect AL0118 | The name 'DeleteRelatedData' does not exist in the current context.
// An internal procedure of another app (Base Application table "Assembly Line", internal procedure ShowAssemblyDocument) called from
// this app: through a record variable, and in a page on that source table as a bare call without and with parentheses and as Rec. without
// parentheses. All give AL0161; the call without parentheses is not let through (it was in 2019). A local procedure of the base table
// (Customer.DeleteRelatedData) named bare in a page on Customer is not found at all (AL0118). Corpus issue 664 items 87 and 88
// (microsoft/AL#5191, #5114, #67). Writer BO. (5 diagnostics)
codeunit 51416 "MNC BO 1413"
{
    procedure Q()
    var
        L: Record "Assembly Line";
    begin
        L.ShowAssemblyDocument();
    end;
}

page 51417 "MNC BO 1413 P"
{
    SourceTable = "Assembly Line";
    layout { area(Content) { field(No; Rec."No.") { } } }

    trigger OnOpenPage()
    begin
        ShowAssemblyDocument;
        ShowAssemblyDocument();
        Rec.ShowAssemblyDocument;
    end;
}

page 51418 "MNC BO 1413 C"
{
    SourceTable = Customer;
    layout { area(Content) { field(No; Rec."No.") { } } }

    trigger OnOpenPage()
    begin
        DeleteRelatedData;
    end;
}
