// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Date'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Date' to 'Integer'. Use an explicit conversion or change the type.
// Writer QW (corpus issue 685): a Date and an Integer branch do not compile in either order (Date arithmetic with an Integer does).
codeunit 52071 "MNC QW Ternary Date Int"
{
    procedure Run1(Cond: Boolean; D: Date)
    var
        R: Date;
    begin
        R := Cond ? D : 5;
        R := Cond ? 5 : D;
    end;
}
