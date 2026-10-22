// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// Corpus issue 670 item 78 (microsoft/AL#8239): Codeunit.Run takes a Record, not a RecordRef. The implicit Record to RecordRef conversion does not
// work the other way. BC 27 (runtime 16.1) gives AL0666 instead: case 1787.
codeunit 50786 "MNC C1786"
{
    procedure Probe()
    var
        RR: RecordRef;
    begin
        RR.Open(18);
        Codeunit.Run(50786, RR);
    end;
}
