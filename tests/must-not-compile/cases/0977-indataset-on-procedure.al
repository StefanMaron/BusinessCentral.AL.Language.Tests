// @expect AL0187 | Attribute 'InDataSet' is valid only for variables.
// InDataSet on a procedure. The attribute is deprecated (AL0667 warning) and valid only on variables.
codeunit 59045 "MNC InDataSet 0977"
{
    [InDataSet]
    procedure Run1()
    begin
    end;
}
