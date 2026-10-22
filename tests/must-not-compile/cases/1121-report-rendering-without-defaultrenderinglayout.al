// @expect AL0721 | Reports that use the rendering syntax must also define the DefaultRenderingLayout property.
// A report with a rendering section and no DefaultRenderingLayout: the compiler does not pick a default layout (corpus issue 646, item 24).
report 51122 "MNC AQ Report 51122"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
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
        layout(L2)
        {
            Type = Word;
            LayoutFile = 'x.docx';
        }
    }
}
