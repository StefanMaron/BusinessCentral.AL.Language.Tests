// @expect AL0169 | The option value 'Foo' is not valid
report 50808 "MNC Y Report 50808"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    PaperSourceDefaultPage = Foo;
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
