// @expect AL0126 | No overload for method 'Foo' takes 2 arguments. Candidates: 'Foo(Integer)' defined in Codeunit 'MNC Codeunit' by the extension Must Not Compile by AL Language (1.0.0.0)
// A call with more arguments than the procedure has parameters.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC Codeunit"
{
    procedure DoIt()
    var
        I: Integer;
        T: Text;
        R: Record "MNC Table";
    begin
        Foo(1, 2);
    end;

    local procedure Foo(A: Integer)
    begin
    end;
}
