// Fixture for TestCodeunitMetadataVirtualTable: a codeunit whose object-level properties
// have known, non-default values, so the "CodeUnit Metadata" (2000000137) columns read back
// from it can be asserted against something other than a blank row.
//
// TableNo binds it to ALT Universal (60000) and makes Rec available in OnRun. SingleInstance
// is deliberately left undeclared so the same fixture also pins the AL default (false).

codeunit 60963 "ALT Codeunit Meta Probe"
{
    TableNo = "ALT Universal";

    trigger OnRun()
    begin
        Rec."Integer Field" := Rec."Integer Field" + 1;
    end;
}
