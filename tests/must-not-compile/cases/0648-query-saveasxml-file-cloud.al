// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'OutStream'
// Query SaveAsXml file from a Cloud app.
query 50648 "MNC Query 50648"
{
    elements
    {
        dataitem(Cust; Customer)
        {
            column(No; "No.") { }
        }
    }
}

codeunit 50648 "MNC Q SaveAsXml File"
{
    procedure Do()
    var
        Q: Query "MNC Query 50648";
        Ok: Boolean;
    begin
        Ok := Q.SaveAsXml('out.xml');
    end;
}
