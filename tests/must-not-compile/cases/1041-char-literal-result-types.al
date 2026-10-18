// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'. Use an explicit conversion or change the type.
// The result of a Char minus a one-character literal is an Integer, so it cannot be assigned to a Text; a Char plus a two-character literal is a Text, so it cannot be assigned to an Integer.
codeunit 50996 "MNC AF Char Literal Result"
{
    procedure Probe(): Text
    var
        C: Char;
        I: Integer;
        T: Text;
    begin
        C := 'a';
        T := C - 'A';
        I := C + 'AB';
        exit(T);
    end;
}
