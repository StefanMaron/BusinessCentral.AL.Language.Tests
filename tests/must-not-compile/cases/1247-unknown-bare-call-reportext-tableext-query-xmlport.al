// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// A bare call of an unknown name in a report extension, a table extension, a query trigger and an xmlport trigger (the table, page, report
// and page extension forms are cases 0030 to 0033). (4 diagnostics)
table 50000 "MNC BB Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
report 50001 "MNC BB Report"
{
    dataset { dataitem(Row; "MNC BB Table") { column(Id; Id) { } } }
}
reportextension 50002 "MNC BB Report Ext" extends "MNC BB Report"
{
    procedure DoIt()
    begin
        NoSuchProcedure();
    end;
}
tableextension 50003 "MNC BB Table Ext" extends "MNC BB Table"
{
    procedure DoIt()
    begin
        NoSuchProcedure();
    end;
}
query 50004 "MNC BB Query"
{
    elements { dataitem(Row; "MNC BB Table") { column(Id; Id) { } } }
    trigger OnBeforeOpen()
    begin
        NoSuchProcedure();
    end;
}
xmlport 50005 "MNC BB XmlPort"
{
    schema { textelement(Root) { tableelement(Row; "MNC BB Table") { fieldelement(Id; Row.Id) { } } } }
    trigger OnPreXmlPort()
    begin
        NoSuchProcedure();
    end;
}
