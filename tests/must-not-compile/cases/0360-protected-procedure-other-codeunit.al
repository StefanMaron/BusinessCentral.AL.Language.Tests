// @expect AL0676 | The member 'Guarded' in object 'MNC C360' cannot be declared as protected in object type 'Codeunit'.
// A protected procedure of another codeunit is called.
codeunit 50182 "MNC C360"
{
    protected procedure Guarded()
    begin
    end;
}

codeunit 50183 "MNC D360"
{
    procedure Run1()
    var
        C: Codeunit "MNC C360";
    begin
        C.Guarded();
    end;
}
