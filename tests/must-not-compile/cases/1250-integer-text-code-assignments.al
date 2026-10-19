// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Code[20]'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'
// I := T (Integer from a Text variable), C := I (Code from Integer) and T := I + 1 (Text from an Integer expression). (3 diagnostics)
codeunit 50000 "MNC BB Codeunit"
{
    procedure DoIt()
    var
        I: Integer;
        T: Text;
        C: Code[20];
    begin
        I := T;
        C := I;
        T := I + 1;
    end;
}
