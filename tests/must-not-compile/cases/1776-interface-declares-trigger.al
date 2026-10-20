// @expect AL0612 | An interface member must be a 'procedure'.
// Corpus #670 item 62 (AL issue 5769). An interface that declares a trigger is refused with AL0612 on BC 27, 28 and 29. A trigger
// cannot be declared, so no implementing procedure can match it.
interface "MNC CW I1776"
{
    trigger OnWhatever();
    begin
    end;
}
