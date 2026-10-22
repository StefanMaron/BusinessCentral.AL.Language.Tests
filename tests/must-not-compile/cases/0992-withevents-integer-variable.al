// @expect AL0458 | 'WithEvents' is not a valid attribute on variables of type 'Integer'
// @target OnPrem
// WithEvents on a variable of a type that has no events (OnPrem app). Runtime test for a DotNet variable: tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al.
codeunit 59120 "MNC WithEventsInt 0992"
{
    var
        [WithEvents]
        Counter: Integer;

    procedure Run1()
    begin
    end;
}
