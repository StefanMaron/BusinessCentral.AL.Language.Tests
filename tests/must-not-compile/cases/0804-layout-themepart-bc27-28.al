// @expect AL0124 | The property 'ThemePart' cannot be used in this context
// @until 28
report 50804 "MNC Y Report 50804"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;

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
            ThemePart = TH1;
        }
    }
}
