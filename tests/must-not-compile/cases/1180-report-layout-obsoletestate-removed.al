// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// A report layout declares ObsoleteState = Removed: a layout takes only No and Pending.
report 51180 "MNC AW R1180"
{
    UsageCategory = None;
    DefaultRenderingLayout = Gone;

    dataset
    {
        dataitem(Num; Integer)
        {
            column(Number; Number) { }
        }
    }

    rendering
    {
        layout(Gone)
        {
            Type = RDLC;
            LayoutFile = './MncAw1180.rdl';
            ObsoleteState = Removed;
            ObsoleteReason = 'Removed';
            ObsoleteTag = '1.0';
        }
    }
}
