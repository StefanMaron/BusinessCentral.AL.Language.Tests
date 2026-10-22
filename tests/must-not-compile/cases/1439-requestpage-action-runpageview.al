// @expect AL0255 | Property 'RunPageView' requires an application object reference for the 'RunObject' property.
// An action of a report request page with RunObject = page and RunPageView (microsoft/AL issue 7716): refused.
report 51439 "MNC BP R1439"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(I; Integer) { }
    }
    requestpage
    {
        layout
        {
            area(Content) { }
        }
        actions
        {
            area(Processing)
            {
                action(Go)
                {
                    RunObject = page "Customer List";
                    RunPageView = where("No." = const('X'));
                }
            }
        }
    }
}
