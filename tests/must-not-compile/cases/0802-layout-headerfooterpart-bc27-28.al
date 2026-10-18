// @expect AL0124 | The property 'HeaderFooterPart' cannot be used in this context
// @until 28
report 50802 "MNC Y Report 50802"
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
            HeaderFooterPart = HF1;
        }
    }
}
