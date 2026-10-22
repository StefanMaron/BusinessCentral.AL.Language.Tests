// @expect AL0296 | The application object or method 'Scoped' has scope 'Internal' and cannot be used for 'Cloud' development.
// A procedure with [Scope('Internal')] called from the same Cloud app.
codeunit 59070 "MNC ScopeInternal 0982"
{
    [Scope('Internal')]
    procedure Scoped()
    begin
    end;

    procedure Run1()
    begin
        Scoped();
    end;
}
