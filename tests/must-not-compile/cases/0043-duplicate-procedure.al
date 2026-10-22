// @expect AL0440 | The Codeunit 'MNC Codeunit' already defines a method called 'Foo' with the same parameter types in 'Must Not Compile by AL Language (1.0.0.0)'.
// Two procedures with the same name and parameters.
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
        I := 1;
    end;

    local procedure Foo(A: Integer)
    begin
    end;

    local procedure Foo(B: Integer)
    begin
    end;
}
