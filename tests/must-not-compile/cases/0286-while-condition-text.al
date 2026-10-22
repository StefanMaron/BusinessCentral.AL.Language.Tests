// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Boolean'. Use an explicit conversion or change the type.
// A Text is used as the condition of a while.
codeunit 50099 "MNC C286"
{
    procedure Run1()
    var
        T: Text;
    begin
        while T do
            T := '';
    end;
}
