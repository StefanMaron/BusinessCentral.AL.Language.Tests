// @expect AL0169 | The option value 'Foo' is not valid
report 50809 "MNC Y Report 50809"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    PaperSourceLastPage = Foo;
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
