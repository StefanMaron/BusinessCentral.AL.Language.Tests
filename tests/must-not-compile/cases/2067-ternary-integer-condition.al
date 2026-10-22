// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// Writer QW (corpus issue 685): the condition of a conditional expression must be a Boolean; an Integer does not convert.
codeunit 52069 "MNC QW Ternary Int Cond"
{
    procedure Run1(A: Integer): Integer
    begin
        exit(A ? 1 : 2);
    end;
}
