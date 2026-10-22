// @expect AL0132 | 'Codeunit "MNC CW C1780"' does not contain a definition for 'Opt'
// @from 29
// Corpus #670 item 68. A default interface method (runtime 18.0, BC 29) is reached only through an Interface variable: calling it on a
// variable of a codeunit that does not declare it is AL0132. BC 27 and 28 refuse the interface body itself (case 0325).
// Interface-variable dispatch: tests/al-language/codeunit/lt-cw-interface-leads/CwDefaultInterfaceMethods.al.
interface "MNC CW I1780"
{
    procedure Opt(): Text
    begin
        exit('default');
    end;
}

codeunit 51780 "MNC CW C1780" implements "MNC CW I1780"
{
}

codeunit 51781 "MNC CW Call1780"
{
    procedure Go(): Text
    var
        C: Codeunit "MNC CW C1780";
    begin
        exit(C.Opt());
    end;
}
