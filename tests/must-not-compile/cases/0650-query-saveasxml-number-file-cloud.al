// @expect AL0133 | Argument 2: cannot convert from 'Text' to 'OutStream'
// Query SaveAsXml number file from a Cloud app.
query 50650 "MNC Query 50650"
{
    elements
    {
        dataitem(Cust; Customer)
        {
            column(No; "No.") { }
        }
    }
}

codeunit 50650 "MNC Q SaveAsXml Number File"
{
    procedure Do()
    var
        Q: Query "MNC Query 50650";
        Ok: Boolean;
    begin
        Ok := Query.SaveAsXml(50650, 'out.xml');
    end;
}
