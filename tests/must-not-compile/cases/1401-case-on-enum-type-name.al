// @expect AL0405 | An option value is expected. Use '::' to access option members (e.g., MyEnum::Value).
// `case Enum::"X" of` with the enum type instead of a value (microsoft/AL issue 4599: once a compiler crash).
enum 51401 "MNC BN E1401"
{
    value(0; A0) { }
    value(1; A1) { }
}

codeunit 51401 "MNC BN C1401"
{
    procedure Run1(): Text
    begin
        case Enum::"MNC BN E1401" of
            Enum::"MNC BN E1401"::A0:
                exit('a0');
        end;
    end;
}
