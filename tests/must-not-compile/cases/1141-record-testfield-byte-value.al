// @expect AL0196 | The call is ambiguous between the method 'TestField(Joker, Integer)'
// Record.TestField(Field, Value) with a Byte variable as the value: the Integer and BigInteger overloads both fit (FieldRef.TestField takes the Byte:
// record/lt-as-records/AsTestFieldTexts.al).
table 51142 "MNC AS T1141"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Num; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 51143 "MNC AS C1141"
{
    procedure Probe()
    var
        Row: Record "MNC AS T1141";
        B: Byte;
    begin
        B := 10;
        Row.TestField(Num, B);
    end;
}
