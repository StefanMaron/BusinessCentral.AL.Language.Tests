// @expect AL0166 | Argument 1: must be a member (field, property, or variable), not an expression or constant.
// @expect AL0166 | Argument 1: must be a member (field, property, or variable), not an expression or constant.
// @expect AL0166 | Argument 1: must be a member (field, property, or variable), not an expression or constant.
// Record.SetRange with one argument that is an enum or option value, not a field (microsoft/AL issue 6238: the call compiled and set no
// filter; corpus issue 668). The forms: Rec.SetRange inside the table with the field's own option value, an enum value of the field's enum
// type, and an option value of a record field.
table 50450 "MNC T1450"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B; }
    }
    keys { key(PK; Id) { Clustered = true; } }

    procedure InTable()
    begin
        Rec.SetRange(Kind::B);
    end;
}

codeunit 50451 "MNC C1450"
{
    procedure Run1()
    var
        R: Record "MNC T1450";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item Ledger Entry Type"::"Assembly Output");
        R.SetRange(R.Kind::B);
    end;
}
