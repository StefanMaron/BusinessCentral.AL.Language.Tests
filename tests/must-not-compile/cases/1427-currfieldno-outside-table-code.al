// @expect AL0118 | The name 'CurrFieldNo' does not exist in the current context.
// @expect AL0132 | 'Record Customer' does not contain a definition for 'CurrFieldNo'
// @expect AL0118 | The name 'CurrFieldNo' does not exist in the current context.
// @expect AL0132 | 'Record Customer' does not contain a definition for 'CurrFieldNo'
// @expect AL0118 | The name 'CurrFieldNo' does not exist in the current context.
// CurrFieldNo exists only in table and table extension code: a codeunit, a page (bare and as Rec.CurrFieldNo), a page extension and a
// record parameter cannot name it. In a table extension it compiles, also as CurrFieldNo := 1 (run time:
// misc/lt-inferred-behaviors/P69CurrFieldNo.al). Corpus issue 664 item 111 (microsoft/AL#4604, #4382). Writer BO. (5 diagnostics)
codeunit 51434 "MNC BO 1427"
{
    procedure Q(): Integer
    begin
        exit(CurrFieldNo);
    end;

    procedure R(C: Record Customer): Integer
    begin
        exit(C.CurrFieldNo);
    end;
}

page 51435 "MNC BO 1427 P"
{
    SourceTable = Customer;
    layout { area(Content) { field(No; Rec."No.") { } } }

    trigger OnOpenPage()
    begin
        if CurrFieldNo = 0 then;
        if Rec.CurrFieldNo = 0 then;
    end;
}

pageextension 51436 "MNC BO 1427 PE" extends "Customer Card"
{
    trigger OnOpenPage()
    begin
        if CurrFieldNo = 0 then;
    end;
}
