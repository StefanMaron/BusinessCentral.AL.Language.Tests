// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'OutStream'
// Query SaveAsCsv file from a Cloud app.
query 50647 "MNC Query 50647"
{
    elements
    {
        dataitem(Cust; Customer)
        {
            column(No; "No.") { }
        }
    }
}

codeunit 50647 "MNC Q SaveAsCsv File"
{
    procedure Do()
    var
        Q: Query "MNC Query 50647";
        Ok: Boolean;
    begin
        Ok := Q.SaveAsCsv('out.csv');
    end;
}
