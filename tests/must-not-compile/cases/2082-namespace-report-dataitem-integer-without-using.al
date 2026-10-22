// @expect AL0185 | Table 'Integer' is missing
// A report in a namespace has a dataitem over the platform table Integer without `using System.Utilities;` (writer RI, al-runtime-rs
// issue 5694).
namespace MNC.RI.NoUsing;

report 50082 "MNC R2082"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Number; Integer)
        {
        }
    }
}
