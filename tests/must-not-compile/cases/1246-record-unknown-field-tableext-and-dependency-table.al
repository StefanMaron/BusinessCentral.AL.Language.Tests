// @expect AL0132 | 'Record "MNC BB Table"' does not contain a definition for 'ExtFieldTypo'
// @expect AL0132 | 'Record Customer' does not contain a definition for 'NoSuchField'
// A field name that does not exist, read from a Record of a table that has a table extension (the extension field is ExtField) and from
// a Record of a table of a dependency app (Customer, Base Application). (2 diagnostics)
table 50000 "MNC BB Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
tableextension 50001 "MNC BB Table Ext" extends "MNC BB Table"
{
    fields { field(50000; ExtField; Integer) { } }
}
codeunit 50002 "MNC BB Codeunit"
{
    procedure ReadExt(): Integer
    var
        R: Record "MNC BB Table";
    begin
        exit(R.ExtFieldTypo);
    end;

    procedure ReadDependency(): Text
    var
        C: Record Customer;
    begin
        exit(C.NoSuchField);
    end;
}
