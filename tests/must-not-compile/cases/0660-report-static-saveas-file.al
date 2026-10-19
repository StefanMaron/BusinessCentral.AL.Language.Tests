// @expect AL0296 | The application object or method 'SaveAsExcel' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsHtml' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsPdf' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsWord' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsXml' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml of the global Report object (object id and file name) are Scope = OnPrem: a Target = Cloud app cannot name them.
report 50000 "MNC T Save Report"
{
    UseRequestPage = false;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }
        }
    }
}

codeunit 50001 "MNC T Static Save"
{
    procedure Save(FileName: Text)
    var
        Ok: Boolean;
    begin
        Ok := Report.SaveAsExcel(Report::"MNC T Save Report", FileName);
        Ok := Report.SaveAsHtml(Report::"MNC T Save Report", FileName);
        Ok := Report.SaveAsPdf(Report::"MNC T Save Report", FileName);
        Ok := Report.SaveAsWord(Report::"MNC T Save Report", FileName);
        Ok := Report.SaveAsXml(Report::"MNC T Save Report", FileName);
    end;
}
