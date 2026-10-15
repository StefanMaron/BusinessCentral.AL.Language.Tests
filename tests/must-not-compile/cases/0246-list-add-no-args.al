// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Value' of 'Add(Integer)'
// List.Add is called without an argument.
codeunit 50052 "MNC C246"
{
    procedure Run1()
    var
        L: List of [Integer];
    begin
        L.Add();
    end;
}
