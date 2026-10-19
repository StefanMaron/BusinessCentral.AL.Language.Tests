// @expect AL0831 | The method 'Foo' is not supported as the implementation for the interface method because it is a try function.
// @expect AL0582 | 'MNC BM C1384b' does not implement the interface member 'MNC BM I1384b.Bar'.
// Corpus #664 item 6. A try function cannot implement an interface method: with a Boolean return in the interface AL0831; without a
// return value the codeunit is reported as not implementing the member (AL0582). The lead named AL0830.
interface "MNC BM I1384a"
{
    procedure Foo(): Boolean;
}
interface "MNC BM I1384b"
{
    procedure Bar();
}
codeunit 51384 "MNC BM C1384a" implements "MNC BM I1384a"
{
    [TryFunction]
    procedure Foo()
    begin
    end;
}
codeunit 51385 "MNC BM C1384b" implements "MNC BM I1384b"
{
    [TryFunction]
    procedure Bar()
    begin
    end;
}
