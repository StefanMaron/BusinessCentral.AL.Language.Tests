// @expect AL0440 | The Codeunit 'MNC BB Codeunit' already defines a method called 'Foo' with the same parameter types
// Foo(var A: Integer) next to Foo(A: Integer): var does not make a different signature (AL0440, as two identical signatures, case 0043).
codeunit 50000 "MNC BB Codeunit"
{
    procedure Foo(var A: Integer)
    begin
    end;

    procedure Foo(A: Integer)
    begin
    end;
}
