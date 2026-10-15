// @expect AL0136 | The loop variable in a 'for' statement must be a numeric type
// A for loop uses a Text variable as the counter.
codeunit 50101 "MNC C288"
{
    procedure Run1()
    var
        T: Text;
    begin
        for T := 1 to 3 do;
    end;
}
