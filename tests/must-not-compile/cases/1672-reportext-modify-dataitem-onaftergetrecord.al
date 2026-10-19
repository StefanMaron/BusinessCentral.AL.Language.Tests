// @expect AL0162 | 'OnAfterGetRecord' is not a valid trigger
// Corpus issue 667, item 155: a modify() of a base data item in a report extension cannot declare OnAfterGetRecord (also on an Integer data item).
// It takes OnBeforeAfterGetRecord / OnAfterAfterGetRecord instead; those run around the base trigger: tests/al-language/reportextensiontrigger/TestReportExtensionTriggers.al.
report 51672 "MNC CJ Base Report"
{
    ProcessingOnly = true;
    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

reportextension 51673 "MNC CJ Base Report Ext" extends "MNC CJ Base Report"
{
    dataset
    {
        modify(Num)
        {
            trigger OnAfterGetRecord()
            begin
            end;
        }
    }
}
