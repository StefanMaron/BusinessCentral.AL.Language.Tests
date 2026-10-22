// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'B' of 'Foo(Integer, Integer)'
// A call with fewer arguments than the procedure has parameters.
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

    local procedure Foo(A: Integer; B: Integer)
    begin
    end;
}
