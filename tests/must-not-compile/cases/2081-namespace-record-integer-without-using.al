// @expect AL0185 | Table 'Integer' is missing
// A codeunit in a namespace declares a Record of the platform table Integer without `using System.Utilities;` (writer RI, al-runtime-rs
// issue 5694). The same code without a namespace, or with the using, compiles (misc/lt-inferred-behaviors/RiNsPlatformTable.al).
namespace MNC.RI.NoUsing;

codeunit 50081 "MNC C2081"
{
    procedure CountTo(Limit: Integer): Integer
    var
        Number: Record Integer;
    begin
        Number.SetRange(Number, 1, Limit);
        exit(Number.Count());
    end;
}
