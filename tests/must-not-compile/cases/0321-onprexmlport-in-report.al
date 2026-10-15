// @expect AL0162 | 'OnPreXmlPort' is not a valid trigger for this object type. Check the object documentation for supported triggers.
// OnPreXmlPort in a report.
report 50138 "MNC R321"
{
    trigger OnPreXmlPort()
    begin
    end;
}
