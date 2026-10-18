// @expect AL0124 | The property 'Subtype' cannot be used in this context
// @until 28
report 50803 "MNC Y Report 50803"
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
            Subtype = Body;
        }
    }
}
