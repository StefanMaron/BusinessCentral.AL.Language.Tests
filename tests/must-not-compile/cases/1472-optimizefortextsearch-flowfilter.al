// @expect AL0223 | The Property 'OptimizeForTextSearch' can only be used if the property 'FieldClass' is set to 'Normal'
// OptimizeForTextSearch = true on a FlowFilter field of type Text (corpus issue 668 item 63).
table 51474 "MNC BR T1472"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; TxtFilter; Text[30]) { FieldClass = FlowFilter; OptimizeForTextSearch = true; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
