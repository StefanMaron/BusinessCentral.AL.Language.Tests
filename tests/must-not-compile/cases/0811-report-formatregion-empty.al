// @expect AL0436 | The value of the property 'FormatRegion' cannot be empty.
report 50811 "MNC Y Report 50811"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    FormatRegion = '';
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
