// @expect AL0223 | The Property 'Subtype' can only be used if the property 'Type' is set to 'Word'
// Runtime 18.0 (BC 29): layout Subtype needs Type = Word. BC 27 and 28 give AL0666 for Subtype instead (case 0803).
// @from 29
report 50805 "MNC Y Report 50805"
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
