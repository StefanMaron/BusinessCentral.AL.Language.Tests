// @expect AL0779 | It is not allowed to call `ModifyAll` on a field of FieldClass='FlowField'.
// @expect AL0779 | It is not allowed to call `ModifyAll` on a field of FieldClass='FlowField'.
// Record.ModifyAll on a FlowField is an error (an own FlowField and Customer."Balance (LCY)"). ModifyAll on a FlowFilter field compiles; its
// run-time result is pinned in tests/al-language/record/lt-record-write/RcBTriggers.al (corpus issue 668).
table 50454 "MNC T1452"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cnt; Integer) { FieldClass = FlowField; CalcFormula = count("MNC T1452"); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50455 "MNC C1452"
{
    procedure Run1()
    var
        R: Record "MNC T1452";
        Customer: Record Customer;
    begin
        R.ModifyAll(Cnt, 0);
        Customer.ModifyAll("Balance (LCY)", 0);
    end;
}
