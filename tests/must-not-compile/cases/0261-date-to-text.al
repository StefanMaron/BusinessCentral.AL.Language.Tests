// @expect AL0122 | Cannot implicitly convert type 'Date' to 'Text'. Use an explicit conversion or change the type.
// A Date is assigned to a Text.
codeunit 50069 "MNC C261"
{
    procedure Run1()
    var
        T: Text;
        D: Date;
    begin
        T := D;
    end;
}
