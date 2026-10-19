// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Text[10]' which is shorter than the converted textual representation of a 'Guid'.
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Code[20]' which is shorter than the converted textual representation of a 'Guid'.
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Code[20]' which is shorter than the converted textual representation of a 'Guid'.
// Corpus #664 item 5. A Guid (a variable or SystemId) assigned to Text[10] or Code[20] is an error, AL0777 (the tracker named AL0778);
// Corpus #664 item 5. A Guid (a variable or SystemId) assigned to Text[10] or Code[20] is an error, AL0777 (the lead named AL0778);
// Code[50] and Text take it. The FlowFilter query column of the same item is case 1380.
table 51371 "MNC BM T1371"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; FFi; Code[20]) { FieldClass = FlowFilter; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 51371 "MNC BM C1371"
{
    procedure P()
    var
        r: Record "MNC BM T1371";
        g: Guid;
        t10: Text[10];
        c20: Code[20];
        c50: Code[50];
        t: Text;
    begin
        t10 := g;
        c20 := r.SystemId;
        c50 := r.SystemId;
        c20 := g;
        t := g;
    end;
}
