// @expect AL0666 | 'Run' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @until 27
// Corpus issue 670 item 78 (microsoft/AL#8239): on BC 27 (app runtime 16.1) Codeunit.Run(Id, RecordRef) is matched to an overload that needs
// runtime 17.0. From BC 28 the same call gives AL0133 (case 1786).
codeunit 50787 "MNC C1787"
{
    procedure Probe()
    var
        RR: RecordRef;
    begin
        RR.Open(18);
        Codeunit.Run(50787, RR);
    end;
}
