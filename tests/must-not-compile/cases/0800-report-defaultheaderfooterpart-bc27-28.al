// @expect AL0666 | 'Subtype' is not available in runtime version '
// @expect AL0666 | 'DefaultHeaderFooterPart' is not available in runtime version '
// Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al.
// @until 28
report 50800 "MNC Y Report 50800"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    DefaultHeaderFooterPart = HF1;
    dataset
    {
        dataitem(D; Integer)
        {
            column(N; Number) { }
        }
    }
    rendering
    {
        layout(L1)
        {
            Type = Word;
            LayoutFile = 'x.docx';

        }
        layout(HF1)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = 'hf.docx';
        }
    }
}
