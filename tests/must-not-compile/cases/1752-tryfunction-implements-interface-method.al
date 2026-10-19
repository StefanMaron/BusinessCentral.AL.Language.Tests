// @expect AL0831 | The method 'DoTest' is not supported as the implementation for the interface method because it is a try function.
// A [TryFunction] procedure cannot implement an interface method, also when the interface method returns Boolean (the return type a
// try function gets). Corpus issue 670 item 30 (AL issue 7558), writer CT. Same verdict on BC 27, 28 and 29.
interface "MNC CT ITest 1752"
{
    procedure DoTest(): Boolean;
}

codeunit 51752 "MNC CT Try Impl 1752" implements "MNC CT ITest 1752"
{
    [TryFunction]
    procedure DoTest()
    begin
    end;
}
