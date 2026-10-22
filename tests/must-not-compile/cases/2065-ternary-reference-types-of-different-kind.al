// @expect AL0122 | Cannot implicitly convert type 'Record "MNC QW Tern B"' to 'Record "MNC QW Tern A"'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Interface "MNC QW Tern I"' to 'Codeunit "MNC QW Tern Impl"'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'List of [Text]' to 'List of [Integer]'. Use an explicit conversion or change the type.
// Writer QW (corpus issue 685): branches of two record types, a codeunit and an interface it implements, and two List types do not compile.
// The same type on both sides compiles (QW_Ternary_ReferenceTypeBranches in tests/al-language/types/TestTernaryContracts.al).
table 52065 "MNC QW Tern A"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

table 52066 "MNC QW Tern B"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

interface "MNC QW Tern I"
{
    procedure Go(): Integer;
}

codeunit 52067 "MNC QW Tern Impl" implements "MNC QW Tern I"
{
    procedure Go(): Integer
    begin
        exit(1);
    end;
}

codeunit 52065 "MNC QW Ternary Ref Kinds"
{
    procedure Run1(Cond: Boolean)
    var
        A: Record "MNC QW Tern A";
        B: Record "MNC QW Tern B";
        C: Codeunit "MNC QW Tern Impl";
        I: Interface "MNC QW Tern I";
        IR: Interface "MNC QW Tern I";
        L1: List of [Integer];
        L2: List of [Text];
        LR: List of [Integer];
    begin
        A := Cond ? A : B;
        IR := Cond ? C : I;
        LR := Cond ? L1 : L2;
    end;
}
