// @expect AL0296 | The application object or method 'EnableExternalAssemblies' has scope 'OnPrem' and cannot be used for 'Cloud' development.
report 50806 "MNC Y Report 50806"
{
    UsageCategory = None;
    DefaultRenderingLayout = L1;
    EnableExternalAssemblies = true;
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
