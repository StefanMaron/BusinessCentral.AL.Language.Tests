// @expect AL0132 | '"MNC E204"' does not contain a definition for 'Purple'
// An enum value that the enum does not have is used.
enum 50006 "MNC E204"
{
    Extensible = true;
    value(0; Red) { }
    value(1; Green) { }
}

codeunit 50007 "MNC C204"
{
    procedure Run1()
    var
        E: Enum "MNC E204";
    begin
        E := "MNC E204"::Purple;
    end;
}
