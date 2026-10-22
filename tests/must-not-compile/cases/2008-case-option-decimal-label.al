// @expect AL0398 | Constant value '1.0' is outside of the valid ordinal range for this Option type
// A case statement on an Option with a Decimal constant as a label (writer QS). Comparing an Option with a Decimal by =, <>, <, >,
// <= and >= compiles (types/PROptionInteger.al, tests QS_*); only a Decimal constant where an Option ordinal is expected is rejected.
codeunit 50000 "MNC Case Option Decimal"
{
    procedure Probe(): Boolean
    var
        O: Option None,Quantity,Amount;
    begin
        case O of
            1.0:
                exit(true);
        end;
        exit(false);
    end;
}
