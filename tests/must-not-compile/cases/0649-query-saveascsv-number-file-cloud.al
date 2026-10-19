// @expect AL0133 | Argument 2: cannot convert from 'Text' to 'OutStream'
// Query SaveAsCsv number file from a Cloud app.
query 50649 "MNC Query 50649"
{
    elements
    {
        dataitem(Cust; Customer)
        {
            column(No; "No.") { }
        }
    }
}

codeunit 50649 "MNC Q SaveAsCsv Number File"
{
    procedure Do()
    var
        Q: Query "MNC Query 50649";
        Ok: Boolean;
    begin
        Ok := Query.SaveAsCsv(50649, 'out.csv');
    end;
}
