// @expect AL0112 | 'Bogus' is not a valid attribute
// The Scope attribute takes OnPrem, Internal or Cloud; any other value is reported as an unknown attribute.
codeunit 59000 "MNC ScopeBogus 0968"
{
    [Scope('Bogus')]
    procedure Run1()
    begin
    end;
}
