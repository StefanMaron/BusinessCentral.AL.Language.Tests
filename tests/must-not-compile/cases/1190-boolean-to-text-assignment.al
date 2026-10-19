// @expect AL0122 | Cannot implicitly convert type 'Boolean' to 'Text'. Use an explicit conversion or change the type.
// A Boolean does not assign to a Text variable (issue 649 item 5; Format(B) is the way to get the text). The runtime side (a Variant holding a
// Boolean assigned to a Text) is in tests/al-language/types/lt-ax-text-format-dates/AxEvaluateText.al.
codeunit 51190 "MNC AX Boolean To Text"
{
    procedure Probe(): Text
    var
        B: Boolean;
        T: Text;
    begin
        B := true;
        T := B;
        exit(T);
    end;
}
