// @expect AL0223 | The Property 'OptimizeForTextSearch' can only be used if the property 'FieldClass' is set to 'Normal'
// OptimizeForTextSearch = true on a Lookup FlowField of type Text (corpus issue 668 item 63).
table 51472 "MNC BR T1471 Src"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
table 51473 "MNC BR T1471"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Looked; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("MNC BR T1471 Src".Txt where(Id = field(Id))); OptimizeForTextSearch = true; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
