// @expect AL0311 | Member 'FromInteger(Integer)' cannot be accessed with an instance reference; qualify it with 'EnumType' instead
// `E := E.FromInteger(1)` on an enum variable (microsoft/AL issue 6003). Enum::"X".FromInteger(1) compiles, and so do Names and Ordinals on
// an instance (tests/al-language/codeunit/lt-enums-interfaces/OjT71043.al).
enum 51402 "MNC BN E1402"
{
    value(0; A0) { }
    value(1; A1) { }
}

codeunit 51402 "MNC BN C1402"
{
    procedure Run1(): Integer
    var
        E: Enum "MNC BN E1402";
    begin
        E := E.FromInteger(1);
        exit(E.AsInteger());
    end;
}
