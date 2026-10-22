// @expect AL0161 | 'Test2()' is inaccessible due to its protection level
// @expect AL0161 | 'MyProc()' is inaccessible due to its protection level
// @expect AL0161 | 'MyProc()' is inaccessible due to its protection level
// @expect AL0161 | 'MyPageProc()' is inaccessible due to its protection level
// A local procedure called through a handle of its own object: a codeunit variable of the same codeunit, Rec. and xRec. inside the table's
// own trigger, CurrPage. inside the page's own trigger. The plain call (no handle) compiles in all three. Other-object forms: cases 0356
// (codeunit) and 0359 (table through a record). Corpus issue 664 items 85 and 86 (microsoft/AL#7246, #6345, #7309). Writer BO. (4 diagnostics)
codeunit 51413 "MNC BO 1412"
{
    local procedure Test2() begin end;

    procedure Q()
    var
        FooBar: Codeunit "MNC BO 1412";
    begin
        Test2();
        FooBar.Test2();
    end;
}

table 51414 "MNC BO 1412 T"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        MyProc();
        Rec.MyProc();
        xRec.MyProc();
    end;

    local procedure MyProc() begin end;
}

page 51415 "MNC BO 1412 P"
{
    SourceTable = "MNC BO 1412 T";
    layout { area(Content) { field(Id; Rec.Id) { } } }

    trigger OnOpenPage()
    begin
        MyPageProc();
        CurrPage.MyPageProc();
    end;

    local procedure MyPageProc() begin end;
}
