// @expect AL0169 | The option value 'Foo' is not valid
report 50807 "MNC Y Report 50807"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    PaperSourceFirstPage = Foo;
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
