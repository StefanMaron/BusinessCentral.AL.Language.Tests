// @expect AL0698 | Type Record "MNC T1770" cannot be used in a 'case' statement.
// A `case` statement over a Record value (here the Record returned by an interface method), with an `else` branch.
// Corpus issue 670 (lead: microsoft/AL issue 6679).
interface "MNC I1770"
{
    procedure GetRec(): Record "MNC T1770";
}

table 50000 "MNC T1770"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50000 "MNC C1770"
{
    procedure Go(I: Interface "MNC I1770")
    var
        R: Record "MNC T1770";
    begin
        case I.GetRec() of
            R:
                ;
            else
                ;
        end;
    end;
}
