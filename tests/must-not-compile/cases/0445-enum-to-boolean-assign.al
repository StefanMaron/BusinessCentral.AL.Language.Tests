// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC P79 Col 0445"' to 'Boolean'. Use an explicit conversion or change the type.
// An Enum is assigned to a Boolean.
codeunit 59445 "MNC P79 0445"
{
    procedure Run1()
    var
        E: Enum "MNC P79 Col 0445";
        B: Boolean;
    begin
        B := E;
    end;
}

enum 59515 "MNC P79 Col 0445"
{
    Extensible = true;
    value(0; Red) { }
    value(1; Green) { }
}
