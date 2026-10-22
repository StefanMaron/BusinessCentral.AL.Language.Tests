// @expect AL0296 | The application object or method 'Scoped' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A procedure with [Scope('OnPrem')] called from the same Cloud app.
codeunit 59065 "MNC ScopeOnPrem 0981"
{
    [Scope('OnPrem')]
    procedure Scoped()
    begin
    end;

    procedure Run1()
    begin
        Scoped();
    end;
}
