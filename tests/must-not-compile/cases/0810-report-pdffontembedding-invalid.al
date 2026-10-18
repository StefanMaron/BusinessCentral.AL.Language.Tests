// @expect AL0169 | The option value 'Foo' is not valid
report 50810 "MNC Y Report 50810"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    PdfFontEmbedding = Foo;
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
