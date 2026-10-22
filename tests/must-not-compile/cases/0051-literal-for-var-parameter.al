// @expect AL0130 | A 'var' argument must be an assignable variable
// A literal passed for a var parameter.
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
        Foo(1);
    end;

    local procedure Foo(var A: Integer)
    begin
    end;
}
