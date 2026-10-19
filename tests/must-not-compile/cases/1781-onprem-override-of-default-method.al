// @expect AL0922 | The method 'Opt' cannot be used as the implementation for the interface method 'MNC CW I1781.Opt' because it has 'OnPrem' scope.
// @from 29
// Corpus #670 item 68. A procedure with [Scope('OnPrem')] cannot override a default interface method (runtime 18.0, BC 29): AL0922, as
// for a required member (case 1377). BC 27 and 28 refuse the interface body itself (case 0325).
interface "MNC CW I1781"
{
    procedure Opt(): Text
    begin
        exit('default');
    end;
}

codeunit 51782 "MNC CW C1781" implements "MNC CW I1781"
{
    [Scope('OnPrem')]
    procedure Opt(): Text
    begin
        exit('own');
    end;
}
