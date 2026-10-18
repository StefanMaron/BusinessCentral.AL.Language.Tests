// @expect AL0124 | The property 'DefaultHeaderFooterPart' cannot be used in this context
// DefaultHeaderFooterPart is a runtime 18 property: BC 27 and 28 compilers do not know it for a report (BC 29 with runtime 16.0: case 0805).
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
            Type = RDLC;
            LayoutFile = 'x.rdlc';

        }
    }
}
