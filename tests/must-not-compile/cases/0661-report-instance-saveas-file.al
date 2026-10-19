// @expect AL0296 | The application object or method 'SaveAsExcel' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsHtml' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsPdf' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsWord' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SaveAsXml' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml on a Report variable (file name) are Scope = OnPrem: a Target = Cloud app cannot call them.
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

codeunit 50001 "MNC T Instance Save"
{
    procedure Save(FileName: Text)
    var
        Rep: Report "MNC T Save Report";
        Ok: Boolean;
    begin
        Ok := Rep.SaveAsExcel(FileName);
        Ok := Rep.SaveAsHtml(FileName);
        Ok := Rep.SaveAsPdf(FileName);
        Ok := Rep.SaveAsWord(FileName);
        Ok := Rep.SaveAsXml(FileName);
    end;
}
