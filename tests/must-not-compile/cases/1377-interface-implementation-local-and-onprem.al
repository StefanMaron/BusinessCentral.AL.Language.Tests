// @expect AL0582 | 'MNC BM C1377a' does not implement the interface member 'MNC BM I1377.Foo'.
// @expect AL0922 | The method 'Foo' cannot be used as the implementation for the interface method 'MNC BM I1377.Foo' because it has 'OnPrem' scope.
// Corpus #664 item 19. A local procedure does not implement an interface method (AL0582; the lead named AL0921). A procedure with
// [Scope('OnPrem')] is refused with AL0922. A procedure named OnRun (not a trigger) is only warning AL0299 (the lead named AL1073).
interface "MNC BM I1377"
{
    procedure Foo();
}
codeunit 51377 "MNC BM C1377a" implements "MNC BM I1377"
{
    local procedure Foo()
    begin
    end;
}
codeunit 51378 "MNC BM C1377b" implements "MNC BM I1377"
{
    [Scope('OnPrem')]
    procedure Foo()
    begin
    end;

    procedure OnRun()
    begin
    end;
}
