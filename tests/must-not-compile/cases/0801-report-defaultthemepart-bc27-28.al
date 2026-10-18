// @expect AL0124 | The property 'DefaultThemePart' cannot be used in this context
// @until 28
report 50801 "MNC Y Report 50801"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
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

        }
    }
}
