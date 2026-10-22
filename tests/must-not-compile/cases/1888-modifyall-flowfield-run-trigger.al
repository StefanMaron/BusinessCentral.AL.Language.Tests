// @expect AL0779 | It is not allowed to call `ModifyAll` on a field of FieldClass='FlowField'.
// ModifyAll(FlowField, value, true) is rejected at compile like the two-argument form (case 1370), also with RunTrigger = true (corpus issue #665 item 4).
table 51888 "MNC DI T1888"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Child Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("MNC DI T1888" where("No." = field("No.")));
        }
    }
}

codeunit 51888 "MNC DI C1888"
{
    procedure P()
    var
        Parent: Record "MNC DI T1888";
    begin
        Parent.ModifyAll("Child Count", 7, true);
    end;
}
