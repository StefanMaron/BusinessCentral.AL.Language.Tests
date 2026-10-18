// @expect AL0666 | 'Subtype' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'DefaultHeaderFooterPart' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Subtype' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'DefaultThemePart' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'Subtype' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'HeaderFooterPart' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @expect AL0666 | 'ThemePart' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @from 29
// @min-al 18
// On BC 29 the header/footer and theme parts and the layout Subtype exist from runtime 18.0; the corpus apps use runtime 16.0.
report 50805 "MNC Y Parts Runtime"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    DefaultHeaderFooterPart = HF1;
    DefaultThemePart = TH1;
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
            Type = RDLC;
            LayoutFile = 'x.rdlc';
            Subtype = Body;
            HeaderFooterPart = HF1;
            ThemePart = TH1;
        }
        layout(HF1)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = 'hf.docx';
        }
        layout(TH1)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = 'th.dotx';
        }
    }
}
