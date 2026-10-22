// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Text[10]' which is shorter than the converted textual representation of a 'Guid'.
// Assigning a Guid to a Text[10] variable: the textual form of a Guid (38 characters) does not fit.
codeunit 51080 "MNC AJ Guid Short Text"
{
    procedure Assign()
    var
        G: Guid;
        Short: Text[10];
    begin
        Short := G;
    end;
}
